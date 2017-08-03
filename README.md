
# Masson

Masson is a configuration management, orchestration and do-anything-you-want
tools. It is here to simplify your life installing complex setup and maintaining
dozens, hundreds, or even thousands of servers.

At [Adaltas], we use it to deploy full featured Hadoop Clusters.

## Installation

Run `npm install` to download the project dependencies.

## Usage

The script `./bin/masson` is used to pilot the various command. Run it without 
any arguments to print the help page or as `./bin/big help {command}` to obtain 
help for a particular command.

## Features

*   SSH: ability to execute remote commands using ssh without having the need
    for any client to run on the servers.
*   Documentation: CoffeeScript Literate provides easy to read and self
    documented code.
*   Code as the single source of thruth
*   Work entirely offline

## Contributors
 
*   David Worms: <https://github.com/wdavidw>

[Adaltas]: http://www.adaltas.com
