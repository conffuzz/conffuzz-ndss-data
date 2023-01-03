# Applying ConfFuzz to Unikraft APIs

In addition to the paper's scenarios, we applied ConfFuzz to [Unikraft](https://unikraft.org). To achieve compatibility with ConFuzz, we used the linux userspace target of Unikraft to get a binary running under Linux. Further, we integrated KASAN into unikraft and added backtrace support. The updated unikraft can be found [here](https://github.com/conffuzz/unikraft).

## Sqlite3

We ran conffuzz on Unikraft under the threat scenario where the `vfscore` internal library is protected from a vulnerable sqlite3 library.

### Building the Unikraft binary

1. Clonning the sources. First clone the [unikraft repo](https://github.com/conffuzz/unikraft). Next clone the external unikraft libraries (see commits used below) used by sqlite3: [newlib](https://github.com/unikraft/lib-newlib), [pthreads-embedded](https://github.com/unikraft/lib-pthread-embedded) an [sqlite](https://github.com/unikraft/lib-sqlite). Finally, clone the [application code](https://github.com/conffuzz/app-sqlite3). You should end up with the following structure.

```sh
├── apps
│   └── app-sqlite
├── libs
│   ├── lib-newlib
│   ├── lib-pthread-embedded
│   └── lib-sqlite
└── unikraft
```

We used the following commits:
- newlib: dea6ac34da547c9ea5831ed4f6044669259285b4
- pthread-embedded: e2705f98bcb17f423547c2394cc672a52de3d1e4
- sqlite: ed967a22894779d62ad1ae8eaadb4c84ed959972

!!! To make things easier, move everything to the `example` folder in your conffuzz clone.

2. Building the binary. Once everything is clonned we spawn a docker container where we will be running conffuzz. Run the following command from the conffuzz root folder:

```sh
make unikraftshell
``` 

Now, in the shell run `make menuconfig` inside the `app-sqlite` folder. Once the menu appears, you can exit. Next we will build the binary using `make build`. This will create a binary under `app-sqlite/build/app-helloworld_linuxu-x86_64.dbg`.

### Running ConFuzz

Now that we have the Unikraft binary, we can run ConFuzz on it. Since we are using KASAN and ConFuzz checks that the binary is built with ASAN, we need to remove this check. Simply comment the following lines from `~/conffuzz/conffuzz.cpp` inside the container:

```C
3603         if (!in_file2.tellg()) {
3604            cerr << cerrPrefix << "Cannot detect ASan on this binary, have you compiled it with -fsanitize=address?" << endl;
3605            return 1;
3606         }
```

Next, we build conffuzz:
```sh
make conffuzz
```

Finally, we run conffuzz on the unikraft binary:
```sh
./conffuzz/conffuzz -x -m -R  /root/examples/apps/app-sqlite/build/app-helloworld_linuxu-x86_64.dbg -r \
"^(close|open|acces|getcwd|stat|fstat|ftruncate|fcntl|read|pread|write|pwrite|fchmod|unlink|mkdir|rmdir|fchown|readlink|lstat|ioctl|utime)$" \
-d /root/examples/apps/app-sqlite/build/app-helloworld_linuxu-x86_64.dbg
```

### Results

We were able to find one interesting KASAN crashes caused by the `open` call. Below is the backtrace of the crash. 

```sh
ERR:  [libkasan] <kasan.c @  155> ==732545==ERROR: AddressSanitizer: SEGV on unknown address 0x7fffffffffffffff at pc 0x0000004c7fcd
ERR:  [libkasan] <kasan.c @  156> READ of size 1 at 0x7fffffffffffffff thread T0
ERR:  [liblinuxuplat] <read_allsymbol.c @  689> Call trace:
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #0 0x403f53 in uk_dump_backtrace+0/0x6c
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #1 0x42e4a6 in shadow_check+0x108/0x253
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #2 0x42e8d9 in __asan_load1_noabort+0x22/0x25
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #3 0x4a86e1 in strlcpy+0x50/0xc6
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #4 0x427964 in path_conv+0x49/0x32b
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #5 0x427c74 in task_conv+0x2e/0x43
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #6 0x4203cd in __uk_syscall_r_open+0xa2/0x147
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #7 0x420327 in uk_syscall_r_open+0x2e/0x32
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #8 0x4202a7 in uk_syscall_e_open+0x2e/0x80
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #9 0x420594 in open+0x122/0x128
ERR:  [liblinuxuplat] <read_allsymbol.c @  662>          #10 0x50bfc1 in posixOpen+0x2b/0x2d
```

We can pass any pointer to the open function and the vfscore will read from the pointer up to `PATH_MAX` character and copy them in a new buffer, allocated on the stack, called `path` which is later passed to `sys_open`. If debugging is enabled, the variable `path` is printed. Thus the attacker could read all the strings from the memory space of `vfscore`. 
