(function(){
  exports.testSomething = function testSomething(test) {
    test.expect(1);
    test.ok(true, "this assertion should pass");
    return test.done();
  };
})();
