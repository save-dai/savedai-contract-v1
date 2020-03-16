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
To run a forked mainnet with ganache, open a tab in your terminal and run:

`ganache-cli -f https://mainnet.infura.io/v3/<INFURA-PROJECTID> --unlock "0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95" --unlock "0x6B175474E89094C44Da98b954EedeAC495271d0F" --unlock "0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667" --unlock "0x98CC3BD6Af1880fcfDa17ac477B2F612980e5e33" --unlock "0xdfbaf3e4c7496dad574a1b842bc85b402bdc298d" --unlock "0xA6923533A6362008e9b536271C2Bdc0FF1467D3c"`

In another tab, `cd` into the project and run:

`truffle test --network mainlocal`

