// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
/**
 * @notice Rules describing how before/after deltas are validated
 */
enum DeltaRule {
    CONSTANT,         // before == after
    INCREASE_EXACT,   // after - before == delta
    DECREASE_EXACT,   // before - after == elta
    INCREASE_MAX,     // after - before <= delta
    INCREASE_MIN,     // after - before >= delta
    DECREASE_MAX,     // before - after <= delta
    DECREASE_MIN      // before - after >= delta  
}

/**
 * @notice Snapshot of contract bytecode hash before and after execution
 */
struct CodeInvariant {
    bytes32 beforeCodeHash;
    bytes32 afterCodeHash;
}

/**
 * @notice Snapshot of a value before and after execution
 */
struct ValuePerPosition {
    uint256 beforeValue;
    uint256 afterValue;
    uint256 delta;
}  

struct AddressInvariant {
    address beforeAddress;
    address afterAddress;
}

/// @notice Mismatched array lengths during invariant validation
error LengthMismatch();

/// @notice Invariant category is not supported
error UnsupportedInvariant();  

/// @notice Invalid or unsupported DeltaRule
error InvalidDeltaRule(DeltaRule deltaRule);

/// @notice Too many slots requested for invariant protection
error ArrayTooLarge(uint256 length, uint256 maxLength);

/// @notice Nonce invariant violation
error InvariantViolationNonce(ValuePerPosition noncePerPosition);

/// @notice Balance invariant violation
error InvariantViolationBalance(ValuePerPosition balancePerPosition);

error InvariantViolationAddress(AddressInvariant[] addressPerPosition);

library InvariantGuardHelper {
    uint256 private constant MAX_PROTECTED_SLOTS  = 0xffff;

    function _processConstantBalance(uint256 beforeBalance, uint256 afterBalance) internal pure {
        if (!_validateDeltaRule(beforeBalance, afterBalance, 0, DeltaRule.CONSTANT)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, 0));
    }

    function _processExactIncreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 exactIncrease) internal pure {
        if (!_validateDeltaRule(beforeBalance, afterBalance, exactIncrease, DeltaRule.INCREASE_EXACT)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, exactIncrease));   
    }

    function _processExactDecreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 exactDecrease) internal pure {
        if (!_validateDeltaRule(beforeBalance, afterBalance, exactDecrease, DeltaRule.DECREASE_EXACT)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, exactDecrease));   
    }

    function _processMaxIncreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 maxIncrease) internal pure {       
        if (!_validateDeltaRule(beforeBalance, afterBalance, maxIncrease, DeltaRule.INCREASE_MAX)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, maxIncrease));   
    }

    function _processMinIncreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 minIncrease) internal pure {     
        if (!_validateDeltaRule(beforeBalance, afterBalance, minIncrease, DeltaRule.INCREASE_MIN)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, minIncrease));      
    }

    function _processMaxDecreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 maxDecrease) internal pure {             
        if (!_validateDeltaRule(beforeBalance, afterBalance, maxDecrease, DeltaRule.DECREASE_MAX)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, maxDecrease));
    }

    function _processMinDecreaseBalance(uint256 beforeBalance, uint256 afterBalance, uint256 minDecrease) internal pure {
        if (!_validateDeltaRule(beforeBalance, afterBalance, minDecrease, DeltaRule.DECREASE_MIN)) revert InvariantViolationBalance(ValuePerPosition(beforeBalance, afterBalance, minDecrease));
    }

    function _validateDeltaRule(uint256 beforeValue, uint256 afterValue, uint256 expectedDelta, DeltaRule deltaRule) internal pure returns (bool) {
        if (deltaRule == DeltaRule.CONSTANT) {
            return beforeValue == afterValue;
        } else if (deltaRule == DeltaRule.INCREASE_EXACT) {
            if (afterValue < beforeValue) return false;
            unchecked {
                return afterValue - beforeValue == expectedDelta;
            }
        } else if (deltaRule == DeltaRule.DECREASE_EXACT) {
            if (beforeValue < afterValue) return false;
            unchecked {
                return beforeValue - afterValue == expectedDelta;
            }
        } else if (deltaRule == DeltaRule.INCREASE_MAX) {
            if (afterValue < beforeValue) return false;
            unchecked {
                return afterValue - beforeValue <= expectedDelta;
            }
        } else if (deltaRule == DeltaRule.INCREASE_MIN) {
            if (afterValue < beforeValue) return false;
            unchecked {
                return afterValue - beforeValue >= expectedDelta;
            }
        } else if (deltaRule == DeltaRule.DECREASE_MAX) {
            if (beforeValue < afterValue) return false;
            unchecked {
                return beforeValue - afterValue <= expectedDelta;
            }
        } else if (deltaRule == DeltaRule.DECREASE_MIN) {
            if (beforeValue < afterValue) return false;
            unchecked {
                return beforeValue - afterValue >= expectedDelta;
            }     
        } else {
            revert InvalidDeltaRule(deltaRule);
        }
    }
}
// Cung cấp khả năng bảo vệ trạng thái 
// bên ngoài hợp đồng hiện tại
// Các hạng mục bảo vệ :
// Số dư ETH địa chỉ bên ngoài (không
// cho phép chúng vi phạm bất biến nếu
// nằm trong khung thực thi của hợp đồng
// hiện tại).
// Lưu ý rằng chúng tôi không hỗ trợ quan 
// sát mã bên ngoài nhằm tuân thủ lộ trình
// EOF.
abstract contract InvariantGuardExternal {
    function _getExtETHBalance(address account) private view returns (uint256) {
        return account.balance;
    }

    modifier invariantExtETHBalance(address account) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processConstantBalance(beforeBalance, afterBalance);
    }

    modifier assertExtETHBalanceEquals(address account, uint256 expected) {
        _;
        uint256 actualBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processConstantBalance(expected, actualBalance);
    }

    modifier exactIncreaseExtETHBalance(address account, uint256 exactIncrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processExactIncreaseBalance(beforeBalance, afterBalance, exactIncrease);
    }

    modifier exactDecreaseExtETHBalance(address account, uint256 exactDecrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processExactDecreaseBalance(beforeBalance, afterBalance, exactDecrease);
    }

    modifier maxIncreaseExtETHBalance(address account, uint256 maxIncrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processMaxIncreaseBalance(beforeBalance, afterBalance, maxIncrease);
    }

    modifier minIncreaseExtETHBalance(address account, uint256 minIncrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processMinIncreaseBalance(beforeBalance, afterBalance, minIncrease);
    }

    modifier maxDecreaseExtETHBalance(address account, uint256 maxDecrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processMaxDecreaseBalance(beforeBalance, afterBalance, maxDecrease);
    }

    modifier minDecreaseExtETHBalance(address account, uint256 minDecrease) {
        uint256 beforeBalance = _getExtETHBalance(account);
        _;
        uint256 afterBalance = _getExtETHBalance(account);
        InvariantGuardHelper._processMinDecreaseBalance(beforeBalance, afterBalance, minDecrease);
    }
}

// Hợp đồng này bảo vệ bất biến trên các token ERC20
// Áp dụng giả định tin tưởng do thực hiện truy vấn bên
// ngoài, vì vậy có thể phát sinh các tình huống không xác
// định nếu hợp đồng token bất thường (metamorphic logic)).
// Các hạng mục bảo vệ : 
// Số dư trên một hoặc nhiều token ERC20 được chỉ định
abstract contract InvariantGuardERC20 {
    function _getERC20Balance(IERC20 token, address account) private view returns (uint256) {
        return token.balanceOf(account);
    }

    modifier invariantERC20Balance(IERC20 token, address account) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processConstantBalance(beforeBalance, afterBalance);
    }

    modifier assertERC20BalanceEquals(IERC20 token, address account, uint256 expected) {
        _;
        uint256 actualBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processConstantBalance(expected, actualBalance);
    }

    modifier exactIncreaseERC20Balance(IERC20 token, address account, uint256 exactIncrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processExactIncreaseBalance(beforeBalance, afterBalance, exactIncrease);
    }

    modifier exactDecreaseERC20Balance(IERC20 token, address account, uint256 exactDecrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processExactDecreaseBalance(beforeBalance, afterBalance, exactDecrease);
    }

    modifier maxIncreaseERC20Balance(IERC20 token, address account, uint256 maxIncrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processMaxIncreaseBalance(beforeBalance, afterBalance, maxIncrease);
    }

    modifier minIncreaseERC20Balance(IERC20 token, address account, uint256 minIncrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processMinIncreaseBalance(beforeBalance, afterBalance, minIncrease);
    }

    modifier maxDecreaseERC20Balance(IERC20 token, address account, uint256 maxDecrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processMaxDecreaseBalance(beforeBalance, afterBalance, maxDecrease);
    }

    modifier minDecreaseERC20Balance(IERC20 token, address account, uint256 minDecrease) {
        uint256 beforeBalance = _getERC20Balance(token, account);
        _;
        uint256 afterBalance = _getERC20Balance(token, account);
        InvariantGuardHelper._processMinDecreaseBalance(beforeBalance, afterBalance, minDecrease);
    }
}

// Hợp đồng này bảo vệ bất biến trên các token ERC721
// Áp dụng giả định tin tưởng do thực hiện truy vấn bên
// ngoài, vì vậy có thể phát sinh các tình huống không xác
// định nếu hợp đồng token bất thường (metamorphic logic)).
// Số dư token ERC721 trên chính nó và các hợp đồng nằm trong
// khung thực thi của nó (áp dụng giả định
// tin tưởng vào hợp đồng token
// Các hạng mục bảo vệ : 
// Số dư trên một hoặc nhiều token ERC721 được chỉ định
// Chủ sở hữu trên một hoặc nhiều token ERC721 được chỉ định
abstract contract InvariantGuardERC721 {
    // BALANCE OF
    function _getERC721Balance(IERC721 token, address account) private view returns (uint256) {
        return token.balanceOf(account);
    }

    modifier invariantERC721Balance(IERC721 token, address account) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processConstantBalance(beforeBalance, afterBalance);
    }

    modifier assertERC721BalanceEquals(IERC721 token, address account, uint256 expected) {
        _;
        uint256 actualBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processConstantBalance(expected, actualBalance);
    }

    modifier exactIncreaseERC721Balance(IERC721 token, address account, uint256 exactIncrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processExactIncreaseBalance(beforeBalance, afterBalance, exactIncrease);
    }

    modifier exactDecreaseERC721Balance(IERC721 token, address account, uint256 exactDecrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processExactDecreaseBalance(beforeBalance, afterBalance, exactDecrease);
    }

    modifier maxIncreaseERC721Balance(IERC721 token, address account, uint256 maxIncrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processMaxIncreaseBalance(beforeBalance, afterBalance, maxIncrease);
    }

    modifier minIncreaseERC721Balance(IERC721 token, address account, uint256 minIncrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processMinIncreaseBalance(beforeBalance, afterBalance, minIncrease);
    }

    modifier maxDecreaseERC721Balance(IERC721 token, address account, uint256 maxDecrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processMaxDecreaseBalance(beforeBalance, afterBalance, maxDecrease);
    }

    modifier minDecreaseERC721Balance(IERC721 token, address account, uint256 minDecrease) {
        uint256 beforeBalance = _getERC721Balance(token, account);
        _;
        uint256 afterBalance = _getERC721Balance(token, account);
        InvariantGuardHelper._processMinDecreaseBalance(beforeBalance, afterBalance, minDecrease);
    }

    // OWNER OF
    function _getERC721Owner(IERC721 token, uint256 tokenId) private view returns (address) {
        return token.ownerOf(tokenId);
    }

    function _getERC721ListOwner(IERC721 token, uint256[] memory tokenIds) private view returns (address[] memory) {
        uint256 length = tokenIds.length;
        address[] memory ownerArray = new address[](length);
        for (uint256 i = 0 ; i < length ; ) {
            ownerArray[i] = _getERC721Owner(token, tokenIds[i]);
        }
        return ownerArray;
    }

    // bất biến chủ sở hữu trước và sau khi thực thi
    modifier invariantOwner(IERC721 token, uint256[] memory tokenIds) {
        address[] memory beforeOwnerArray = _getERC721ListOwner(token, tokenIds);
        _;
        address[] memory afterOwnerArray = _getERC721ListOwner(token, tokenIds);
        _processConstantOwner(beforeOwnerArray, afterOwnerArray);
    }

    // bất biến chủ sở hữu kì vọng và thực tế sau khi thực thi
    modifier assertOwnerEquals(IERC721 token, uint256[] memory tokenIds, address[] memory expectedArray) {
        _;
        address[] memory actualOwnerArray = _getERC721ListOwner(token, tokenIds);
        _processConstantOwner(expectedArray, actualOwnerArray);
    }

    function _processConstantOwner(address[] memory beforeOwnerArray, address[] memory afterOwnerArray) private pure {
        (uint256 violationCount, AddressInvariant[] memory violations) = _validateAddressArray(beforeOwnerArray, afterOwnerArray);
        if (violationCount > 0) revert InvariantViolationAddress(violations); 
    }

    function _validateAddressArray(address[] memory beforeOwnerArray, address[] memory afterOwnerArray) private pure returns (uint256, AddressInvariant[] memory) {
        uint256 length = afterOwnerArray.length;
        if (beforeOwnerArray.length != length) revert LengthMismatch();
        bool valueMismatch;       
        uint256 violationCount;
        AddressInvariant[] memory violations = new AddressInvariant[](length);
        for (uint256 i = 0 ; i < length ; ) {
            valueMismatch = beforeOwnerArray[i] == afterOwnerArray[i];
            assembly {
                violationCount := add(violationCount, valueMismatch)
            }
            violations[i] = AddressInvariant(beforeOwnerArray[i], afterOwnerArray[i]);
            unchecked { ++i; }
        }
        return (violationCount, violations);
    }
}
