// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;
import "./InvariantGuardHelper.sol";

// * @author Helkomine (@Helkomine) *
// Hợp đồng này bảo vệ bất biến trên các token ERC20
// Áp dụng giả định tin tưởng do thực hiện truy vấn bên
// ngoài, vì vậy có thể phát sinh các tình huống không xác
// định nếu hợp đồng token bất thường (metamorphic logic)).
// Các hạng mục bảo vệ : 
// Số dư trên một hoặc nhiều token ERC20 được chỉ định
abstract contract InvariantGuardERC20 {
    using InvariantGuardHelper for *;

    modifier invariantERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processConstantERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray);
    }

    modifier assertERC20BalanceEquals(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory expectedArray) {
        _;
        uint256[] memory actualBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processConstantERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), actualBalanceArray, expectedArray);
    }

    modifier exactIncreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory exactIncreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processExactIncreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, exactIncreaseArray);
    }

    modifier maxIncreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory maxIncreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processMaxIncreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, maxIncreaseArray);
    }

    modifier minIncreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory minIncreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processMinIncreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, minIncreaseArray);
    }

    modifier exactDecreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory exactDecreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processExactDecreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, exactDecreaseArray);
    }

    modifier maxDecreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory maxDecreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processMaxDecreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, maxDecreaseArray);
    }

    modifier minDecreaseERC20Balance(IERC20[] memory tokenArray, address[] memory accountArray, uint256[] memory minDecreaseArray) {
        uint256[] memory beforeBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _;
        uint256[] memory afterBalanceArray = _getERC20BalanceArray(tokenArray, accountArray);
        _processMinDecreaseERC20Balance(ERC20ArrayInvariant(tokenArray), AccountArrayInvariant(accountArray), beforeBalanceArray, afterBalanceArray, minDecreaseArray);
    }

    function _getERC20Balance(IERC20 token, address account) private view returns (uint256) {
        return token.balanceOf(account);
    }

    function _getERC20BalanceArray(IERC20[] memory tokenArray, address[] memory accountArray) private view returns (uint256[] memory) {
        uint256 length = accountArray._getAddressArrayLength();
        length._revertIfArrayTooLarge();
        uint256[] memory balanceArray = new uint256[](length);
        for (uint256 i = 0 ; i < length ; ) {
            balanceArray[i] = _getERC20Balance(tokenArray[i], accountArray[i]);
            unchecked { ++i; }
        }
        return balanceArray;
    }

    function _processConstantERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, beforeBalanceArray._getUint256ArrayLength()._emptyArray(), DeltaConstraint.NO_CHANGE);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processExactIncreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory exactIncreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, exactIncreaseArray, DeltaConstraint.INCREASE_EXACT);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processMaxIncreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory maxIncreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, maxIncreaseArray, DeltaConstraint.INCREASE_MAX);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processMinIncreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory minIncreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, minIncreaseArray, DeltaConstraint.INCREASE_MIN);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processExactDecreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory exactDecreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, exactDecreaseArray, DeltaConstraint.DECREASE_EXACT);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processMaxDecreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory maxDecreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, maxDecreaseArray, DeltaConstraint.DECREASE_MAX);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }

    function _processMinDecreaseERC20Balance(ERC20ArrayInvariant memory tokenERC20ArrayInvariant, AccountArrayInvariant memory accountArrayInvariant, uint256[] memory beforeBalanceArray, uint256[] memory afterBalanceArray, uint256[] memory minDecreaseArray) private pure {
        (uint256 violationCount, ValuePerPosition[] memory violations) = beforeBalanceArray._validateDeltaArray(afterBalanceArray, minDecreaseArray, DeltaConstraint.DECREASE_MIN);
        if (violationCount > 0) revert InvariantViolationERC20BalanceArray(tokenERC20ArrayInvariant, accountArrayInvariant, violations); 
    }
}
