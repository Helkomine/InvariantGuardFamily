# INVARIANT-GUARD

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

## Bối cảnh

`DELEGATECALL` ra đời từ rất sớm (EIP-7), đây là một phiên bản kế nhiệm được đánh giá là an toàn hơn so với `CALLCODE`. `DELEGATECALL` rất đặc biệt khi cho phép hợp đồng gọi tải và thực thi mã của địa chỉ đích trên chính nó, ngụ ý rằng mã của người được ủy quyền có thể làm thay đổi bộ nhớ của người gọi nó, đây là điểm đặc biệt mà lệnh `CALL` không thể thay thế hoàn toàn được. Ngoài khả năng thực thi mã được ủy quyền, nó cũng ưu việt hơn `CALLCODE` nhờ khả năng giữ nguyên `msg.sender` và `msg.value`, điều này rất hữu ích cho các suy luận tức thời trong bối cảnh thực thi sử dụng mã ủy quyền.

Kể từ đó cho đến nay giao thức vẫn chưa có bước cải tiến nào dành cho mã lệnh này, tuy nhiên không có nghĩa là không có vấn đề nào phát sinh. Thực tế khối lượng công việc bổ sung khi sử dụng `DELEGATECALL` luôn ở mức đáng kể, đặc biệt trong khâu quản lý an toàn bộ nhớ. Bất kỳ sự thiếu nhất quán nào trong quản lý bố cục hay các điểm ra vào có thể dẫn đến những hậu quả thảm khốc, một ví dụ điển hình là vụ tấn công vào ví đa chữ ký Parity, kẻ tấn công sử dụng `DELEGATECALL` trên hợp đồng implementation (hợp đồng này cung cấp logic dùng chung cho một hệ sinh thái ví đa chữ ký), hành động này kích hoạt `SELFDESTRUCT` qua đó phá hủy hoàn toàn hợp đồng logic này, hậu quả là các ví dùng nó như nguồn logic vĩnh viễn không thể sử dụng được.

Đã có những nỗ lực nhằm giảm thiểu tác động tiêu cực của mã lệnh này, bao gồm việc giới thiệu không gian tên để phân chia rõ ràng các vùng lưu trữ (ERC-7201), tuy nhiên đây chỉ là giải pháp liên quan đến bố cục với giả định proxy ủy quyền đến một hợp đồng logic tuân thủ chuẩn, ngụ ý rằng có ít nhất cách hợp lệ để làm tan vỡ bố cục này, chẳng hạn vô tình kích hoạt logic độc hại trên một hợp đồng cửa hậu, đây là một vấn đề đặc biệt nghiêm trọng với các mô hình hợp đồng thông minh dạng module, khi người dùng được trao quyền cài đặt các module

Một vấn đề nhức nhối mà các lập trình viên gặp phải khi sử dụng DELEGATECALL là sự thay đổi trạng thái ngoài ý muốn, điều này xảy ra khi một hợp đồng được ủy quyền không hoạt động đúng cách hoặc chứa các cửa hậu độc hại. Hệ quả là các lập trình viên trở nên nhát tay khi sử dụng DELEGATECALL, một số sử dụng CALL để thay thế, nhưng nó 

Các nhà phát triển phải nắm rõ những hạn chế cố hữu của module tích hợp này và dự phóng an toàn cho những vị trí mà module này không bảo vệ được. Chính vì những hạn chế như vậy mà tác giả khuyến nghị chỉ sử dụng chúng để bảo vệ những vị trí trọng yếu, chằng hạn như con trỏ proxy, chủ sở hữu, hoặc những vị trí được tuyên bố là bất biến dựa trên đặc tả ban đầu.
