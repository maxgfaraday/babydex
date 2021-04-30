# To setup an Ethereum smart contract project:



<hr>

## Tools you will need:

### Install node

* %> brew install node
(This will give you the npm command)

### Install the project tools for Ethereum development

* [Truffle and Ganache](https://www.trufflesuite.com/)

``` bash
%> npm install truffle -g
%> npm install -g ganache-cli
```

Regarding Ganache for a nicer UI install the tool from [the Ganache site](https://www.trufflesuite.com/ganache)
<hr>

## Now, set up your project (Here are the commands….)

``` bash
%> mkdir <project>
%> cd <project>
%> cp ~/.gitignore_truffle ./.gitignore
%> cp ~/.header_6thcolumn ./.header
%> git init
%> npm init
%> truffle init
%> npm install @openzeppelin/contracts
%> emacs truffle-config (change “solc:” stanza “version” to “0.8.0”)
%> git add .
%> git commit -am “initial commit”
```
(note: we are ignoring all the openzeppelin code under node_modules)

<b>Now you are ready to start writing your smart contract!</b>

Edit/create the appropriate ```migrations``` file(s), compile and run:

``` bash
%> truffle compile
%> truffle develop
```
The last command will launch a local faux Ethereum node and give you an interactive prompt to hold context for the locally deployed contract. At the prompt you can run "migrate" to build and (re)deploy your contract
(Use the ```--reset``` flag with ```migrate``` when you want to force a clean rebuild)

In the interactive environment you can run ```migrate``` and then get a handle to the deployed contract and make calls against it

``` bash
let instance myContract = await MyContract.deployed();
myContract.foo();
```
Remember that you can't ```let``` more than once.

<hr>

## We will write our own DEX!

[Final Project](https://tinyurl.com/w5bm9nwc)

Notes:
