# Set Up
- Install nvm:
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash`
- Install node:
`nvm install node` (13.8.0)

npm install -g truffle

upgrade drizzle and react npm package versions?

Download parity:
https://releases.parity.io/ethereum/v2.7.2/x86_64-apple-darwin/parity

chmod +x parity
./parity --warp --chain kovan
Wait for sync

In root folder:
npm install --save truffle-hdwallet-provider


glow despair unveil below range artwork rice coyote public coffee room scrub

# Testing

### Setup Infura Environment Variable

If using zsh:  
`echo 'export INFURA_PROJECTID=your_project_ID_here' >> ~/.zshenv`  
`source ~/.zshenv`

### Run forked mainnet with Ganache

To run a forked mainnet with Ganache, open a tab in your terminal and run:

`ganache-cli -f https://mainnet.infura.io/v3/$INFURA_PROJECTID --unlock "0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95" --unlock "0x6B175474E89094C44Da98b954EedeAC495271d0F" --unlock "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33" --unlock "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643" --unlock "0x274d9e726844ab52e351e8f1272e7fc3f58b7e5f"`

In another tab, `cd` into the project and run:

`truffle test --network mainlocal`

