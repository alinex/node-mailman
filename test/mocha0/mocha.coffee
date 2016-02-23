chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

describe "Simple mocha test", ->
  it "should add two numbers", ->
    expect(2+2).is.equal 4
