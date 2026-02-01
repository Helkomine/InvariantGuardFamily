# INVARIANT-GUARD-FAMILY
# Invariant Guard Library

## Overview
This library provides invariant-based enforcement for:
- Balance
- Storage
- Transient Storage
- Contract Code

## Design Philosophy
- Invariants over inline requires
- Explicit delta rules
- Audit-first error reporting

## DeltaRule Model
- CONSTANT
- INCREASE_EXACT / DECREASE_EXACT
- INCREASE_MAX / DECREASE_MAX
- INCREASE_MIN / DECREASE_MIN

## Storage vs Transient Storage
- `storage` uses native Solidity storage references
- `transient storage` is currently modeled via memory arrays
- Design anticipates future EOF / transient keywords

## Modifier Usage Guidelines
- Recommended modifier order
- Invalid combinations
- Examples

## Gas & Performance Notes
- Array-based validation
- Error accumulation strategy
- Future optimization paths

## Security Considerations
- Reentrancy model assumptions
- Callback safety
- Interaction with selfdestruct / code changes


Giúp việc thực hiện DELEGATECALL trở nên an toàn hơn

Một vấn đề nhức nhối mà các lập trình viên gặp phải khi sử dụng DELEGATECALL là sự thay đổi trạng thái ngoài ý muốn, điều này xảy ra khi một hợp đồng được ủy quyền không hoạt động đúng cách hoặc chứa các cửa hậu độc hại. Hệ quả là các lập trình viên trở nên nhát tay khi sử dụng DELEGATECALL, một số sử dụng CALL để thay thế, nhưng nó

Các nhà phát triển phải nắm rõ những hạn chế cố hữu của module tích hợp này và dự phóng an toàn cho những vị trí mà module này không bảo vệ được. Chính vì những hạn chế như vậy mà tác giả khuyến nghị chỉ sử dụng chúng để bảo vệ những vị trí trọng yếu, chằng hạn như con trỏ proxy, chủ sở hữu, hoặc những vị trí được tuyên bố là bất biến dựa trên đặc tả ban đầu.
