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
