var HelloEth = artifacts.require('./HelloEth.sol');
contract('HelloEth', function(accounts) {
  it("should assert true", function(done) {

    var hello_eth = HelloEth.deployed();

hello_eth.then(function(contract){
return contract.GetMessage.call();
}).then(function(result){

assert.isTrue(result == 'Hello Test!');
    done();
})
});
});
