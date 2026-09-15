# คืนอาร์กิวเมนต์ที่ถูกย้ายความเป็นเจ้าของเมื่อเกิดข้อผิดพลาด

## คำอธิบาย

หากฟังก์ชันที่อาจเกิดข้อผิดพลาดได้ (fallible function) มีการย้ายความเป็นเจ้าของ (move/consume) อาร์กิวเมนต์เข้าไปในฟังก์ชัน ให้ส่งคืนอาร์กิวเมนต์ตัวนั้นกลับออกมาภายในข้อมูลข้อผิดพลาด (error) ด้วยเสมอ

## ตัวอย่าง

```rust
pub fn send(value: String) -> Result<(), SendError> {
    println!("using {value} in a meaningful way");
    // Simulate non-deterministic fallible action.
    use std::time::SystemTime;
    let period = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap();
    if period.subsec_nanos() % 2 == 1 {
        Ok(())
    } else {
        Err(SendError(value))
    }
}

pub struct SendError(String);

fn main() {
    let mut value = "imagine this is very long string".to_string();

    let success = 's: {
        // Try to send value two times.
        for _ in 0..2 {
            value = match send(value) {
                Ok(()) => break 's true,
                Err(SendError(value)) => value,
            }
        }
        false
    };

    println!("success: {success}");
}
```

## แรงจูงใจ

เมื่อเกิดข้อผิดพลาดขึ้น คุณอาจต้องการลองใช้วิธีอื่น หรือพยายามทำซ้ำใหม่ (retry) ในกรณีที่ฟังก์ชันนั้นให้ผลลัพธ์ไม่แน่นอน (non-deterministic) ทว่าหากอาร์กิวเมนต์ถูกส่งมอบความเป็นเจ้าของและสูญหายไปทุกครั้งที่เกิดข้อผิดพลาด คุณจะถูกบีบให้ต้องคัดลอกข้อมูล (`.clone()`) ก่อนเรียกใช้งานเสมอ ซึ่งส่งผลเสียต่อประสิทธิภาพของโปรแกรม

ไลบรารีมาตรฐานของ Rust ใช้แนวทางนี้ในหลายจุด เช่น เมท็อด `String::from_utf8` โดยเมื่อส่งเวกเตอร์ของไบต์ที่ไม่ได้ประกอบขึ้นเป็น UTF-8 ที่ถูกต้อง ตัวเมท็อดจะคืนค่าความผิดพลาดเป็น `FromUtf8Error` ซึ่งคุณสามารถเรียกใช้เมท็อด `FromUtf8Error::into_bytes` เพื่อนำเวกเตอร์เดิมที่ส่งเข้าไปกลับคืนมาได้

## ข้อดี

เพิ่มประสิทธิภาพการทำงานอย่างชัดเจน เนื่องจากสามารถโอนย้ายความเป็นเจ้าของของอาร์กิวเมนต์ได้โดยไม่ต้องกังวลเรื่องการโคลนข้อมูลล่วงหน้า

## ข้อเสีย

โครงสร้างของชนิดข้อมูลข้อผิดพลาด (error types) มีความซับซ้อนเพิ่มขึ้นเล็กน้อย
