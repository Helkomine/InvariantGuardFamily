# INVARIANT-GUARD

Giúp việc thực hiện DELEGATECALL trở nên an toàn hơn

## Bối cảnh

`DELEGATECALL` ra đời từ rất sớm (EIP-7), đây là một phiên bản kế nhiệm được đánh giá là an toàn hơn so với `CALLCODE`. `DELEGATECALL` rất đặc biệt khi cho phép hợp đồng gọi tải và thực thi mã của địa chỉ đích trên chính nó, ngụ ý rằng mã của người được ủy quyền có thể làm thay đổi bộ nhớ của người gọi nó, đây là điểm đặc biệt mà lệnh `CALL` không thể thay thế hoàn toàn được. Ngoài khả năng thực thi mã được ủy quyền, nó cũng ưu việt hơn `CALLCODE` nhờ khả năng giữ nguyên `msg.sender` và `msg.value`, điều này rất hữu ích cho các suy luận tức thời trong bối cảnh thực thi sử dụng mã ủy quyền.

Kể từ đó cho đến nay giao thức vẫn chưa có bước cải tiến nào dành cho mã lệnh này, tuy nhiên không có nghĩa là không có vấn đề nào phát sinh. Thực tế khối lượng công việc bổ sung khi sử dụng `DELEGATECALL` luôn ở mức đáng kể, đặc biệt trong khâu quản lý an toàn bộ nhớ. Bất kỳ sự thiếu nhất quán nào trong quản lý bố cục hay các điểm ra vào có thể dẫn đến những hậu quả thảm khốc, một ví dụ điển hình là vụ tấn công vào ví đa chữ ký Parity, kẻ tấn công sử dụng `DELEGATECALL` trên hợp đồng implementation (hợp đồng này cung cấp logic dùng chung cho một hệ sinh thái ví đa chữ ký), hành động này kích hoạt `SELFDESTRUCT` qua đó phá hủy hoàn toàn hợp đồng logic này, hậu quả là các ví dùng nó như nguồn logic vĩnh viễn không thể sử dụng được.

Đã có những nỗ lực nhằm giảm thiểu tác động tiêu cực của mã lệnh này, bao gồm việc giới thiệu không gian tên để phân chia rõ ràng các vùng lưu trữ (ERC-7201), tuy nhiên đây chỉ là giải pháp liên quan đến bố cục với giả định proxy ủy quyền đến một hợp đồng logic tuân thủ chuẩn, ngụ ý rằng có ít nhất một cách hợp lệ để làm tan vỡ bố cục này, chẳng hạn vô tình kích hoạt logic độc hại trên một hợp đồng cửa hậu. Đây là một vấn đề đặc biệt nghiêm trọng với các mô hình hợp đồng thông minh dạng module, khi người dùng được trao quyền cài đặt các module tùy chỉnh. Rất ít người dùng có đủ trình độ để phân tích sự an toàn của các module này, một khi đã cài vào, chúng âm thầm chờ đợi cho đến khi người dùng thực hiện các giao dịch trông có vẻ vô hại nhưng thực ra đang kích hoạt cơ chế cho phép kẻ tấn công chiếm toàn bộ quyền kiểm soát ví và gây ra hậu quả không thể lường trước. Một số nhóm cẩn trọng đã cài đặt các logic kiểm soát giá trị trước và sau khi thực thi, điều này giảm thiểu các tác động tiềm tàng khi sử dụng `DELEGATECALL`, tuy nhiên chúng vẫn chưa được truyền bá rộng rãi - điều này khiến đại bộ phận các nhà phát triển vẫn loay hoay tìm giải pháp an toàn khi sử dụng `DELEGATECALL`, nghĩa là một số lượng lớn hợp đồng đã và đang được tạo ra luôn trong thế bị động, một sai sót nhỏ trong bước thực thi đều dẫn đến mất hoàn toàn khả năng kiểm soát.  

Dựa trên ý tưởng đó, tác giả đã cung cấp một bản triển khai hoàn chỉnh, với tên gọi ban đầu là Safe-Delegatecall, tuy nhiên sau đó được đổi tên thành Invariant-Guard để hướng đến mục tiêu tham vọng hơn trong việc kiểm soát sự thay đổi trạng thái không chỉ riêng `DELEGATECALL` mà còn cho tất cả các mã lệnh có tiềm năng thay đổi trạng thái khác. 

Đây là phiên bản triển khai công khai lần đầu tiên cho Invariant-Guard bằng Solidity, rất mong nhận được sự đánh giá từ cộng đồng. Ngoài ra tác giả còn đang sở hữu một EIP về vấn đề này nhằm cung cấp khả năng bảo vệ mang tính toàn cục, bạn có thể tham khảo tại đây : 

##  Hướng dẫn sử dụng

Hiện tại Invariant-Guard đang có bốn phiên bản là InvariantGuardInternal, InvariantGuardExternal, InvariantGuardERC20 và InvariantGuardERC721

## Lời giải thích ngắn gọn về EIP

Các nhà phát triển phải nắm rõ những hạn chế cố hữu của module tích hợp này và dự phóng an toàn cho những vị trí mà module này không bảo vệ được. Chính vì những hạn chế như vậy mà tác giả khuyến nghị chỉ sử dụng chúng để bảo vệ những vị trí trọng yếu, chằng hạn như con trỏ proxy, chủ sở hữu, hoặc những vị trí được tuyên bố là bất biến dựa trên đặc tả ban đầu.
