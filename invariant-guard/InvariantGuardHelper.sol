// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice Rules describing how before/after deltas are validated
 */
enum DeltaConstraint {
    NO_CHANGE,         // before == after
    INCREASE_EXACT,    // after - before == delta
    INCREASE_MAX,      // after - before <= delta
    INCREASE_MIN,      // after - before >= delta
    DECREASE_EXACT,    // before - after == delta
    DECREASE_MAX,      // before - after <= delta
    DECREASE_MIN       // before - after >= delta  
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

// snapshot địa chỉ trước và sau thực thi
struct AddressInvariant {
    address beforeOwner;
    address afterOwner;
}

// mảng địa chỉ cần kiểm tra bất biến
struct AccountArrayInvariant {
    address[] accountArray;
}

// bí danh của mảng token ERC20 cần kiểm tra bất biến
struct ERC20ArrayInvariant {
    IERC20[] tokenERC20ArrayInvariant;
}

// bí danh của mảng token ERC721 cần kiểm tra bất biến
struct ERC721ArrayInvariant {
    IERC721[] tokenERC721ArrayInvariant;
}

// bí danh của mảng tokenId ERC721 cần kiểm tra bất biến
struct ERC721TokenIdArray {
    uint256[] tokenIdERC721Array;
}

/// @notice Mismatched array lengths during invariant validation
error LengthMismatch();

/// @notice Invariant category is not supported
error UnsupportedInvariant();  

/// @notice Invalid or unsupported DeltaRule
error InvalidDeltaConstraint(DeltaConstraint deltaConstraint);

/// @notice Too many slots requested for invariant protection
error ArrayTooLarge(uint256 length, uint256 maxLength);

/// @notice Code hash invariant violation
error InvariantViolationCode(CodeInvariant codeInvariant);

/// @notice Nonce invariant violation
error InvariantViolationNonce(ValuePerPosition noncePerPosition);

/// @notice Balance invariant violation
error InvariantViolationBalance(ValuePerPosition balancePerPosition);

/// @notice Storage invariant violation
error InvariantViolationStorage(ValuePerPosition[] storagePerPosition);

/// @notice Transient storage invariant violation
error InvariantViolationTransientStorage(ValuePerPosition[] transientStoragePerPosition);

// Vi phạm bất biến số dư ETH ngoài hợp đồng
error InvariantViolationExtETHBalanceArray(AccountArrayInvariant accountArrayInvariant, ValuePerPosition[] extETHBalancePerPosition);

// Vi phạm bất biến số dư ERC20
error InvariantViolationERC20BalanceArray(ERC20ArrayInvariant tokenERC20ArrayInvariant, AccountArrayInvariant accountArrayInvariant, ValuePerPosition[] ERC20BalancePerPosition);

// Vi phạm bất biến số dư ERC721
error InvariantViolationERC721BalanceArray(ERC721ArrayInvariant tokenERC721ArrayInvariant, AccountArrayInvariant accountArrayInvariant, ValuePerPosition[] ERC721BalancePerPosition);

// Vi phạm bất biến chủ sở hữu dựa trên tokenId ERC721
error InvariantViolationERC721OwnerArray(ERC721ArrayInvariant tokenERC721ArrayInvariant, ERC721TokenIdArray tokenIdERC721Array, AddressInvariant[] addressInvariantArray);

// Thư viện logic cho Invariant Guard
library InvariantGuardHelper {
    uint256 internal constant MAX_PROTECTED_SLOTS  = 0xffff;

    // tạo mảng trống uint256
    function _emptyArray(uint256 length) internal pure returns (uint256[] memory) {
        return new uint256[](length);
    }
    
    // Lấy kích thước mảng bytes32
    function _getBytes32ArrayLength(bytes32[] memory bytes32Array) internal pure returns (uint256) {
        return bytes32Array.length;
    } 

    // Lấy kích thước mảng uint256
    function _getUint256ArrayLength(uint256[] memory uint256Array) internal pure returns (uint256) {
        return uint256Array.length;
    }

    // Lấy kích thước mảng address
    function _getAddressArrayLength(address[] memory accountArray) internal pure returns (uint256) {
        return accountArray.length;
    }

    // hoàn nguyên nếu kích thước quá lớn
    function _revertIfArrayTooLarge(uint256 numPositions) internal pure {
        if (numPositions > MAX_PROTECTED_SLOTS) revert ArrayTooLarge(numPositions, MAX_PROTECTED_SLOTS);
    }  

    /**
     * @notice Validates a before/after delta using a DeltaRule
     * @return True if the invariant holds, false otherwise
     */
    function _isDeltaViolation(uint256 beforeValue, uint256 afterValue, uint256 expectedDelta, DeltaConstraint deltaConstraint) internal pure returns (bool) {
        if (deltaConstraint == DeltaConstraint.NO_CHANGE) {
            return beforeValue != afterValue;
        } else if (deltaConstraint == DeltaConstraint.INCREASE_EXACT) {
            if (afterValue < beforeValue) return true;
            unchecked {
                return afterValue - beforeValue != expectedDelta;
            }
        } else if (deltaConstraint == DeltaConstraint.INCREASE_MAX) {
            if (afterValue < beforeValue) return true;
            unchecked {
                return afterValue - beforeValue > expectedDelta;
            }
        } else if (deltaConstraint == DeltaConstraint.INCREASE_MIN) {
            if (afterValue < beforeValue) return true;
            unchecked {
                return afterValue - beforeValue < expectedDelta;
            }
        } else if (deltaConstraint == DeltaConstraint.DECREASE_EXACT) {
            if (beforeValue < afterValue) return true;
            unchecked {
                return beforeValue - afterValue != expectedDelta;
            }
        } else if (deltaConstraint == DeltaConstraint.DECREASE_MAX) {
            if (beforeValue < afterValue) return true;
            unchecked {
                return beforeValue - afterValue > expectedDelta;
            }
        } else if (deltaConstraint == DeltaConstraint.DECREASE_MIN) {
            if (beforeValue < afterValue) return true;
            unchecked {
                return beforeValue - afterValue < expectedDelta;
            }     
        } else {
            revert InvalidDeltaConstraint(deltaConstraint);
        }
    }

    /**
     * @notice Validates array-based invariants
     * @return violationCount Number of invariant violations
     * @return violations Detailed per-position violations
     */
    function _validateDeltaArray(uint256[] memory beforeValueArray, uint256[] memory afterValueArray, uint256[] memory expectedDeltaArray, DeltaConstraint deltaConstraint) internal pure returns (uint256, ValuePerPosition[] memory) {
        uint256 length = _getUint256ArrayLength(expectedDeltaArray);
        _revertIfArrayTooLarge(length);
        if (_getUint256ArrayLength(beforeValueArray) != length || _getUint256ArrayLength(afterValueArray) != length) revert LengthMismatch();
        bool valueMismatch;       
        uint256 violationCount;
        ValuePerPosition[] memory violations = new ValuePerPosition[](length);
        for (uint256 i = 0 ; i < length ; ) {            
            valueMismatch = _isDeltaViolation(beforeValueArray[i], afterValueArray[i], expectedDeltaArray[i], deltaConstraint);
            assembly {
                violationCount := add(violationCount, valueMismatch)
            }
            violations[i] = ValuePerPosition(beforeValueArray[i], afterValueArray[i], expectedDeltaArray[i]);
            unchecked { ++i; }
        }
        return (violationCount, violations);
    }
    
    // Xác minh địa chỉ trước và sau thực thi có bị thay đổi hay không, trả về giá trị violationCount > 0 nếu có
    function _validateAddressArray(address[] memory beforeOwnerArray, address[] memory afterOwnerArray) internal pure returns (uint256, AddressInvariant[] memory) {
        uint256 length = _getAddressArrayLength(afterOwnerArray);
        _revertIfArrayTooLarge(length);
        bool valueMismatch;
        uint256 violationCount;
        AddressInvariant[] memory violations = new AddressInvariant[](length);
        for (uint256 i = 0 ; i < length ; ) {            
            valueMismatch = beforeOwnerArray[i] != afterOwnerArray[i];
            assembly {
                violationCount := add(violationCount, valueMismatch)
            }
            violations[i] = AddressInvariant(beforeOwnerArray[i], afterOwnerArray[i]);
            unchecked { ++i; }
        }
        return (violationCount, violations);
    }
}
