module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  rpc: {
    host: 'localhost',
    port: '8545'
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
//      from: "0xe9685d55834fdb8e07f02c7d72e89f4f53ef5238"
    },
    rinkeby: {
      host: "localhost",
      port: 8545,
      from: "0x2482802cD33e700c28226Cc93fb667769DdC3A20",
      network_id: "*", // Match any network id
      gas: 4612388
      //gas: 7748771
      //gas: 6712390000
    }
  }
};
