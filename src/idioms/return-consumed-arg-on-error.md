# คืนอาร์กิวเมนต์ที่ถูกบริโภคเมื่อเกิดข้อผิดพลาด

## คำอธิบาย

หากฟังก์ชันที่ล้มเหลวได้ (fallible function) บริโภค (ย้าย) อาร์กิวเมนต์ ให้คืนอาร์กิวเมนต์นั้นกลับมาภายในข้อผิดพลาดด้วย

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

เมื่อเกิดข้อผิดพลาด คุณอาจต้องการลองวิธีอื่นหรือลองทำซ้ำในกรณีที่เป็นฟังก์ชันที่ให้ผลไม่แน่นอน แต่ถ้าอาร์กิวเมนต์ถูกบริโภคไปเสมอ คุณก็ถูกบังคับให้โคลนมันทุกครั้งที่เรียก ซึ่งไม่มีประสิทธิภาพนัก

ไลบรารีมาตรฐานใช้แนวทางนี้ในเมท็อดอย่าง `String::from_utf8` เมื่อได้รับเวกเตอร์ที่ไม่มี UTF-8 ที่ถูกต้อง มันจะคืน `FromUtf8Error` กลับมา และคุณได้เวกเตอร์ตัวเดิมคืนมาด้วยเมท็อด `FromUtf8Error::into_bytes`

## ข้อดี

ประสิทธิภาพดีขึ้นเพราะย้ายอาร์กิวเมนต์ได้ทุกเมื่อที่ทำได้

## ข้อเสีย

ชนิดข้อมูลข้อผิดพลาดซับซ้อนขึ้นเล็กน้อย
