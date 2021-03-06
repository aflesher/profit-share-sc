pragma solidity ^0.4.21;


/**
 * @title SafeMath8
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath8 {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint8 a, uint8 b) internal pure returns (uint8 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}