// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";

/// @notice Library to execute an external program using a 2-way communication channel
/// This allow more complex scripting using any languages that support socket/named pipe communication
library Exec {

    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm =
        Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------

    /// @notice Execute an external program using a 2-way communication channel
    /// This allow the program to execute request in forge while being executed
    /// THis is achieved using an IPC channel created for this purpose.
    /// @param program path to the executable
    /// @param args the list of argument to pass to the `program`
    function execute(
        string memory program,
        string[] memory args
    ) internal returns (bytes memory result) {
        bytes memory init = init1193(program, args);

        // we get the  processID from `forge-exec-ipc-client`
        // it should always be correct
        string memory processID = abi.decode(init, (string));

        // the response sent to the program as an hex encoded string
        string memory response = "0x"; // the first response is empty

        // we will repeat the following until the program send us a termination request (requestType == 0)
        while (true) {
            // we call the program
            bytes memory request = call1193(processID, response);

            if (request.length == 0) {
                terminate1193(processID, "INVALID_REQUEST");
            }

            // TODO (for all abi.decode below)
            // we would like to try catch abi.decode (See https://github.com/ethereum/solidity/issues/10381)
            // so we can terminate the program if an error happen in the decoding
            // this is especially important since if we revert here we won't be able to tell the executing process to terminate
            // for now the program should have a timeout mechanism to exit on its own if no replies comes in from forge
            // Note though that this might pause problem for someone debugging step by step

            // we get decode the outer layer, giving us the request type
            (uint256 requestType, bytes memory requestData) = abi.decode(
                request,
                (uint256, bytes)
            );

            // Termination request
            if (requestType == 0x00) {
                result = requestData;
                // we stop right here and got our result field with the program's last response data
                break;
            }
            // Call Request
            else if (requestType == 0xf1) {
                (
                    bool broadcast,
                    address from,
                    bytes memory data,
                    address payable to,
                    uint256 value
                ) = abi.decode(requestData, (bool, address, bytes, address, uint256));
                handleSender(from, broadcast);

                if (to != address(0)) {
                    (bool success, bytes memory returnData) = to.call{
                        value: value
                    }(data);
                    response = vm.toString(abi.encode(success, returnData));
                } else {
                    // we emulate tx send to address(0) by using the create opcode:
                    address addr;
                    assembly {
                        addr := create(0, add(data, 0x20), mload(data))
                    }
                    response = vm.toString(abi.encode(addr != address(0), ""));
                }
            }
            // Static Call
            else if (requestType == 0xfa) {
                (
                    address from,
                    bytes memory data,
                    address payable to
                ) = abi.decode(requestData, (address, bytes, address));
                handleSender(from, false);
                (bool success, bytes memory returnData) = to.staticcall(data);
                response = vm.toString(abi.encode(success, returnData));
            }
            // Create
            else if (requestType == 0xf0) {
                (bool broadcast, address from, bytes memory data, uint256 value) = abi.decode(
                    requestData,
                    (bool, address, bytes, uint256)
                );
                handleSender(from, broadcast);

                address addr;
                assembly {
                    addr := create(value, add(data, 0x20), mload(data))
                }
                response = vm.toString(addr);
            }
            // Create2
            else if (requestType == 0xf5) {
                (bool broadcast, address from, bytes memory data, uint256 value, bytes32 salt) = abi.decode(
                    requestData,
                    (bool, address, bytes, uint256, bytes32)
                );
                handleSender(from, broadcast);

                address addr;
                assembly {
                    addr := create2(value, add(data, 0x20), mload(data), salt)
                }
                response = vm.toString(addr);
            }
            // GetBalance Request
            else if (requestType == 0x31) {
                address account = abi.decode(requestData, (address));
                response = vm.toString(account.balance);
            }
            // GetCode(address)
            else if (requestType == 0x3c) {
                address account = abi.decode(requestData, (address));
                response = vm.toString(account.code);
            }
            // GetCodeHash(address)
            else if (requestType == 0x3f) {
                address account = abi.decode(requestData, (address));
                response = vm.toString(account.codehash);
            }
            // GetCodeSize(address)
            else if (requestType == 0x3b) {
                address account = abi.decode(requestData, (address));
                response = vm.toString(account.code.length);
            }
            // GetBlockHash(num)
            else if (requestType == 0x40) {
                uint256 num = abi.decode(requestData, (uint256));
                response = vm.toString(blockhash(num));
            }
            // GetTimestamp()
            else if (requestType == 0x42) {
                response = vm.toString(block.timestamp);
            }
            // GetBlocknumber()
            else if (requestType == 0x43) {
                response = vm.toString(block.number);
            }
            // GetChainId()
            else if (requestType == 0x46) {
                assembly {
                    response := chainid()
                }
            }
            // Send
            else if (requestType == 0xf100) {
                (bool broadcast, address from, address payable to, uint256 value) = abi.decode(
                    requestData,
                    (bool, address, address, uint256)
                );
                handleSender(from, broadcast);

                bool success = to.send(value);
                response = vm.toString(success);
            }
            else {
                terminate1193(processID, "UNKNOWN_REQUEST_TYPE");
            }
        }
    }


    // --------------------------------------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------------------------------------

    function handleSender(address from, bool broadcast) internal {
        if (broadcast) {
            vm.broadcast(from);
        } else if (from != address(0)) {
            vm.prank(from, from);
        }
    }

    /// @dev this call `forge-exec-ipc-client` with the init command
    /// `forge-exec-ipc-client` will spawn the `program` in a sperate process
    /// It will give that process a specific IPC socket/named pipe path to use
    /// and return it to forge as an abi encoded string
    /// @param program path to the executable
    /// @param args the list of argument to pass to the `program`
    function init1193(
        string memory program,
        string[] memory args
    ) private returns (bytes memory) {
        string[] memory inputs = new string[](args.length + 3);
        inputs[0] = "forge-exec-ipc-client";
        inputs[1] = "init";
        inputs[2] = program;
        for (uint256 i = 0; i < args.length; i++) {
            inputs[i + 3] = args[i];
        }
        return vm.ffi(inputs);
    }

    /// @dev this call `forge-exec-ipc-client` with the terminate command
    /// `forge-exec-ipc-client` will send the `terminate` messae via IPC to the program
    /// @param id the IPC socket/named-pipe path decoded from `init1193` call
    /// @param errorMessage an error message that `forge-exec-ipc-client` will forward to the program
    function terminate1193(
        string memory id,
        string memory errorMessage
    ) private {
        string[] memory inputs = new string[](4);
        inputs[0] = "forge-exec-ipc-client";
        inputs[1] = "terminate";
        inputs[2] = id;
        inputs[3] = errorMessage;

        vm.ffi(inputs);
        revert(errorMessage);
    }

    /// @dev this call `forge-exec-ipc-client` with the exec command
    /// `forge-exec-ipc-client` will send the `exec` messae via IPC to the program
    /// @param id the IPC socket/named-pipe path decoded from `init1193` call
    /// @param value the response encoded as string that `forge-exec-ipc-client` will forward to the program
    function call1193(
        string memory id,
        string memory value
    ) private returns (bytes memory) {
        string[] memory inputs = new string[](4);
        inputs[0] = "forge-exec-ipc-client";
        inputs[1] = "exec";
        inputs[2] = id;
        inputs[3] = value;

        return vm.ffi(inputs);
    }
}
