# <h1 align="center"> forge-exec </h1>

**Execute programs from forge with am open 2-way communication channel between both**

## Installation

Install `forge-exec` as git submodules in your foundry project.

```bash
forge install wighawag/forge-exec
```

Install `forge-exec-ipc-client` on your machine, see [release files](https://github.com/wighawag/forge-exec/releases/tag/forge-exec-ipc-client-v0.0.2)

This need to be in your `PATH`

You can also easily instal from source, see folder: [forge-exec-ipc-client](./forge-exec-ipc-client/)

```bash
cargo install forge-exec-ipc-client
```

This command line tool allows `forge-exec` to maintain a 2-way commincation channel with the program being executed.

Tnis means the program is able to send request to forge (create, call, send, ...) and get responses and this until the program wish to stop.

## Usage

1. Add this import to your script or test:

```solidity
import {Exec} from "forge-exec/Exec.sol";
```

1. Execute an external program:

```solidity
string[] memory args = new string[](1);
args[0] = "./example.js";
bytes memory result = Exec.execute("node", args, false); // the third parameter (false) tell whether to broadcast any tx or not
```

1. You must enable [ffi](https://book.getfoundry.sh/cheatcodes/ffi.html) in order to use the library. You can either pass the `--ffi` flag to any forge commands you run (e.g. `forge script Script --ffi`), or you can add `ffi = true` to your `foundry.toml` file.

> Note The program executed need to create an IPC server to communicate back with forge, see how it works in [forge-exec-ipc-client's README.md](./forge-exec-ipc-client/README.md).
>
> You can use the npm package `forge-exec-ipc-server` for that. See [repo](https://github.com/wighawag/forge-exec-ipc-server-js)

## Javascript Setup

Setup your js project with npm

```
npm init
```

Then install `forge-exec-ipc-server` package which will let the script to communicate back with forge

```
npm i -D forge-exec-ipc-server
```

Now you can write your js script this way

```js
import { execute } from "forge-exec-ipc-server";

execute(async (forge) => {
  const address = await forge.create({
    from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    data: "0x608060405234801561001057600080fd5b5060f78061001f6000396000f3fe6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea2646970667358221220f0cfb2159c518c3da0ad864362bad5dc0715514a9ab679237253d506773a0a1b64736f6c63430008130033",
  });
  console.log({ address: address });
});
```

for now, only create, send, call and balance are implemented

### Example

We have example usage for both [tests](./demo-js/test/Exec.t.sol) and [scripts](./demo-js/script/ExecDemo.s.sol). See [example.js](./demo-js/example.js) in the [demo-js folder](./demo-js/)

## Rust

`forge-exec` is agnostic to what program you execute, you just need to follow the ipc communication protocol. you can find a very basic rust example in the [demo-rust folder](./demo-rust/)

## Why?

[Forge scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) allow you to perform deployment task in solidity. With forge-exec you can run external program to deploy contracts and more. 

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.


## Quick Start

```
mkdir my-forge-exec-project;
cd my-forge-exec-project;
forge init;

forge install wighawag/forge-exec;

cat >> .gitignore <<EOF

node_modules/
.ipc.log
EOF
cat > package.json <<EOF
{
  "name": "my-forge-exec-project",
  "private": true,
  "type": "module",
  "devDependencies": {
    "forge-exec-ipc-server": "0.0.1"
  },
  "scripts": {
    "execute": "forge script --ffi script/Counter.s.sol -vvvvv"
  }
}
EOF

cat >> remappings.txt <<EOF
forge-exec/=lib/forge-exec/src/
EOF

pnpm i

cat > script/example.js <<EOF
// @ts-check
import { execute } from "forge-exec-ipc-server";
execute(async (forge) => {
  const results = await Promise.all([
    forge.create({
      from: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
      data: "0x608060405234801561001057600080fd5b5060f78061001f6000396000f3fe6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea2646970667358221220f0cfb2159c518c3da0ad864362bad5dc0715514a9ab679237253d506773a0a1b64736f6c63430008130033",
    }),
  ]);

  const tx = await forge.send({
    to: "0x0000000000000000000000000000000000000001",
    value: 1n,
  });
  console.log({ tx: tx });
  return {
    types: results.map(() => ({
      type: "address",
    })),
    values: results,
  };
});
EOF
cat > script/Counter.s.sol <<EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Exec} from "forge-exec/Exec.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        string[] memory args = new string[](1);
        args[0] = "./script/example.js";
        Exec.execute("node", args, true);
    }
}
EOF

# we ensure forge-exec-ipc-client is in the path
# you can install it as mentioned in the README
PATH=lib/forge-exec/forge-exec-ipc-client/bin:$PATH pnpm execute;
```