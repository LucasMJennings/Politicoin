/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

//  var HDWalletProvider = require('truffle-hdwallet-provider');
//  var mnemonic = 'name hungry announce crew kidney van miracle okay emotion dinner cannon tackle';
//
//  module.exports = {
//   // See <http://truffleframework.com/docs/advanced/configuration>
//   // to customize your Truffle configuration!
//   networks: {
//     rinkeby: {
//       provider: function() {
//         return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/f41a8cf7f0dc47f29d0547ba918b69a9');
//       },
//       network_id: 1,
//       gas: 4500000,
//       gasPrice:  1000000000
//     }
//   }
// };

 module.exports = {
   networks: {
     development: {
       host: "127.0.0.1",
       port: 7545,
       network_id: "*",
       gas: 200000000,
       gasPrice:  1
     }
   }
 };
