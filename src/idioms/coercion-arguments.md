# ใช้ชนิดที่ถูกยืมสำหรับอาร์กิวเมนต์

## คำอธิบาย

การใช้เป้าหมายของ deref coercion สามารถเพิ่มความยืดหยุ่นให้กับโค้ดของคุณเมื่อต้องตัดสินใจว่าจะใช้อาร์กิวเมนต์ชนิดใดให้กับพารามิเตอร์ของฟังก์ชัน ด้วยวิธีนี้ ฟังก์ชันจะรับข้อมูลนำเข้าได้หลากหลายชนิดขึ้น

สิ่งนี้ไม่ได้จำกัดอยู่แค่ชนิดที่แปลงเป็นสไลซ์ได้หรือชนิดพอยน์เตอร์แบบอ้วน (fat pointer) เท่านั้น อันที่จริง คุณควรเลือกใช้**ชนิดที่ถูกยืม**แทน**การยืมชนิดที่เป็นเจ้าของ**เสมอ เช่น `&str` แทน `&String`, `&[T]` แทน `&Vec<T>` หรือ `&T` แทน `&Box<T>`

การใช้ชนิดที่ถูกยืมช่วยให้คุณหลีกเลี่ยงชั้นของการอ้อมผ่าน (indirection) ซ้อนกัน ในกรณีที่ชนิดที่เป็นเจ้าของมีชั้นของการอ้อมผ่านอยู่แล้ว ตัวอย่างเช่น `String` มีชั้นของการอ้อมผ่านหนึ่งชั้น ดังนั้น `&String` จะมีสองชั้น เราหลีกเลี่ยงได้โดยใช้ `&str` แทน แล้วปล่อยให้ `&String` ถูกบังคับแปลง (coerce) เป็น `&str` เมื่อมีการเรียกฟังก์ชัน

## ตัวอย่าง

ในตัวอย่างนี้ เราจะแสดงความแตกต่างบางประการระหว่างการใช้อาร์กิวเมนต์ฟังก์ชันแบบ `&String` กับการใช้ `&str` แต่แนวคิดเดียวกันนี้ใช้ได้กับการใช้ `&Vec<T>` เทียบกับ `&[T]` หรือการใช้ `&Box<T>` เทียบกับ `&T` เช่นกัน

ลองพิจารณาตัวอย่างที่เราต้องการตรวจสอบว่าคำหนึ่งคำมีสระติดกันสามตัวหรือไม่ เราไม่จำเป็นต้องเป็นเจ้าของสตริงเพื่อตรวจสอบสิ่งนี้ จึงใช้การอ้างอิงแทน

โค้ดอาจมีหน้าตาประมาณนี้:

```rust
fn three_vowels(word: &String) -> bool {
    let mut vowel_count = 0;
    for c in word.chars() {
        match c {
            'a' | 'e' | 'i' | 'o' | 'u' => {
                vowel_count += 1;
                if vowel_count >= 3 {
                    return true;
                }
            }
            _ => vowel_count = 0,
        }
    }
    false
}

fn main() {
    let ferris = "Ferris".to_string();
    let curious = "Curious".to_string();
    println!("{}: {}", ferris, three_vowels(&ferris));
    println!("{}: {}", curious, three_vowels(&curious));

    // This works fine, but the following two lines would fail:
    // println!("Ferris: {}", three_vowels("Ferris"));
    // println!("Curious: {}", three_vowels("Curious"));
}
```

โค้ดนี้ทำงานได้ดีเพราะเราส่งชนิด `&String` เป็นพารามิเตอร์ หากเราลบเครื่องหมายคอมเมนต์ในสองบรรทัดสุดท้ายออก ตัวอย่างจะล้มเหลว เนื่องจากชนิด `&str` จะไม่ถูกบังคับแปลงเป็นชนิด `&String` เราซ่อมได้โดยเพียงแก้ชนิดของอาร์กิวเมนต์

ตัวอย่างเช่น หากเราเปลี่ยนประกาศฟังก์ชันเป็น:

```rust, ignore
fn three_vowels(word: &str) -> bool {
```

ทั้งสองเวอร์ชันก็จะคอมไพล์ผ่านและพิมพ์ผลลัพธ์เดียวกัน

```bash
Ferris: false
Curious: true
```

แต่เดี๋ยวก่อน ยังมีมากกว่านั้น! เรื่องนี้ยังมีประเด็นต่ออีก คุณอาจคิดในใจว่า ไม่เป็นไรหรอก ยังไงฉันก็ไม่เคยใช้ `&'static str` เป็นข้อมูลนำเข้าอยู่ดี (อย่างที่เราทำตอนใช้ `"Ferris"`) แม้จะมองข้ามตัวอย่างพิเศษนี้ไป คุณก็ยังคงพบว่าการใช้ `&str` ให้ความยืดหยุ่นมากกว่าการใช้ `&String`

ทีนี้ลองดูตัวอย่างที่ใครสักคนให้ประโยคมาประโยคหนึ่ง แล้วเราต้องการตรวจสอบว่ามีคำใดในประโยคนั้นที่มีสระติดกันสามตัวหรือไม่ เราน่าจะนำฟังก์ชันที่นิยามไว้แล้วมาใช้ โดยป้อนคำแต่ละคำจากประโยคเข้าไป

ตัวอย่างอาจมีหน้าตาดังนี้:

```rust
fn three_vowels(word: &str) -> bool {
    let mut vowel_count = 0;
    for c in word.chars() {
        match c {
            'a' | 'e' | 'i' | 'o' | 'u' => {
                vowel_count += 1;
                if vowel_count >= 3 {
                    return true;
                }
            }
            _ => vowel_count = 0,
        }
    }
    false
}

fn main() {
    let sentence_string =
        "Once upon a time, there was a friendly curious crab named Ferris".to_string();
    for word in sentence_string.split(' ') {
        if three_vowels(word) {
            println!("{word} has three consecutive vowels!");
        }
    }
}
```

การรันตัวอย่างนี้โดยใช้ฟังก์ชันที่ประกาศด้วยอาร์กิวเมนต์ชนิด `&str` จะให้ผลลัพธ์

```bash
curious has three consecutive vowels!
```

อย่างไรก็ตาม ตัวอย่างนี้จะรันไม่ได้เมื่อฟังก์ชันของเราประกาศด้วยอาร์กิวเมนต์ชนิด `&String` เนื่องจาก string slice มีชนิดเป็น `&str` ไม่ใช่ `&String` การแปลงเป็น `&String` ต้องมีการจัดสรรหน่วยความจำและไม่ใช่การแปลงโดยนัย ขณะที่การแปลงจาก `String` เป็น `&str` นั้นราคาถูกและเกิดขึ้นโดยนัย

## ดูเพิ่มเติม

- [Rust Language Reference ว่าด้วย Type Coercions](https://doc.rust-lang.org/reference/type-coercions.html)
- สำหรับการอภิปรายเพิ่มเติมเกี่ยวกับวิธีจัดการ `String` และ `&str` ดู
  [บทความชุดนี้ (2015)](https://web.archive.org/web/20201112023149/https://hermanradtke.com/2015/05/03/string-vs-str-in-rust-functions.html)
  โดย Herman J. Radtke III
- [บล็อกของ Steve Klabnik ว่าด้วย 'When should I use String vs &str?'](https://archive.ph/LBpD0)
