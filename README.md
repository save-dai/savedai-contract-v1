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

`ganache-cli -f https://mainnet.infura.io/v3/<INFURA-PROJECTID> --unlock 0xdfbaf3e4c7496dad574a1b842bc85b402bdc298d`

In another tab, `cd` into the project and run:

`truffle test`

