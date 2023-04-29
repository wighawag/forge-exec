#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
if (fs.existsSync("node_modules/forge-exec-ipc-client")) {
    fs.chmodSync("node_modules/forge-exec-ipc-client/bin/forge-exec-ipc-client", 0764);
    fs.mkdirSync("node_modules/.bin", {recursive: true});
    const folder_path = path.resolve('node_modules/forge-exec-ipc-client/bin');
    const file_path = path.join(folder_path, 'forge-exec-ipc-client');
    const content = fs.readFileSync(file_path, 'utf-8');
    const new_folder_path = 'node_modules/.bin/';
    const new_file_path = path.join(new_folder_path, 'forge-exec-ipc-client');
    const relative_path = path.relative(new_folder_path, folder_path);
    fs.writeFileSync(new_file_path, content.replace(`$DIR/\${TARGET}/forge-exec-ipc-client`, `$DIR/${path.join(relative_path, `\${TARGET}/forge-exec-ipc-client`)}`))
    fs.chmodSync(new_file_path, 0764);
} else {
    console.error(`Please install "forge-exec-ipc-client", this contains the executable needed for forge-exec to operate`)
}