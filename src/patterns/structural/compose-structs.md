# การกระจายโครงสร้าง struct เพื่อการยืมที่เป็นอิสระต่อกัน (Struct decomposition for independent borrowing)

## คำอธิบาย

ในบางครั้ง การสร้าง struct ขนาดใหญ่ที่มีฟิลด์ข้อมูลจำนวนมากอาจนำไปสู่ปัญหาติดขัดกับระบบ borrow checker — แม้ว่าในทางทฤษฎีแล้วแต่ละฟิลด์จะสามารถถูกยืมแยกจากกันได้อย่างเป็นอิสระ แต่บ่อยครั้งที่ทั้ง struct กลับถูกเรียกใช้งานพร้อมกัน จนส่งผลให้เกิดการล็อกและขัดขวางไม่ให้ฟิลด์อื่นถูกนำไปใช้งานได้ แนวทางแก้ไขปัญหานี้คือการแยก (decompose) struct ขนาดใหญ่ออกเป็น struct ย่อยๆ หลายตัว จากนั้นจึงนำ struct ย่อยเหล่านั้นมาประกอบ (compose) รวมกันกลับเข้ามาใน struct หลัก ซึ่งจะช่วยให้แต่ละ struct ย่อยสามารถถูกยืมใช้งานแยกจากกันได้อย่างเป็นอิสระและมีความยืดหยุ่นสูงขึ้น

นอกจากนี้ แนวทางดังกล่าวยังมักจะนำไปสู่การออกแบบที่ดีขึ้นในภาพรวมอีกด้วย เนื่องจากกระบวนการแยกส่วน struct มักจะช่วยให้เราค้นพบหน่วยการทำงานย่อย (smaller units of functionality) ที่มีความชัดเจนและเป็นโมดูลมากขึ้น

## ตัวอย่าง

นี่คือตัวอย่างจำลองสถานการณ์ที่ borrow checker เข้ามาขัดขวางการเรียกใช้งาน struct ของเรา:

```rust,ignore
struct Database {
    connection_string: String,
    timeout: u32,
    pool_size: u32,
}

fn print_database(database: &Database) {
    println!("Connection string: {}", database.connection_string);
    println!("Timeout: {}", database.timeout);
    println!("Pool size: {}", database.pool_size);
}

fn main() {
    let mut db = Database {
        connection_string: "initial string".to_string(),
        timeout: 30,
        pool_size: 100,
    };

    let connection_string = &mut db.connection_string;
    print_database(&db);
    *connection_string = "new string".to_string();
}
```

คอมไพเลอร์จะรายงานข้อผิดพลาดดังต่อไปนี้:

```ignore
let connection_string = &mut db.connection_string;
                        ------------------------- mutable borrow occurs here
print_database(&db);
               ^^^ immutable borrow occurs here
*connection_string = "new string".to_string();
------------------ mutable borrow later used here
```

เราสามารถนำแพตเทิร์นนี้มาประยุกต์ใช้เพื่อรีแฟกเตอร์ `Database` ให้กลายเป็น struct ย่อย 3 ตัว ซึ่งจะช่วยคลี่คลายปัญหาการตรวจสอบการยืมของ borrow checker ได้อย่างหมดจด:

```rust
// Database is now composed of three structs - ConnectionString, Timeout and PoolSize.
// Let's decompose it into smaller structs
#[derive(Debug, Clone)]
struct ConnectionString(String);

#[derive(Debug, Clone, Copy)]
struct Timeout(u32);

#[derive(Debug, Clone, Copy)]
struct PoolSize(u32);

// We then compose these smaller structs back into `Database`
struct Database {
    connection_string: ConnectionString,
    timeout: Timeout,
    pool_size: PoolSize,
}

// print_database can then take ConnectionString, Timeout and Poolsize struct instead
fn print_database(connection_str: ConnectionString, timeout: Timeout, pool_size: PoolSize) {
    println!("Connection string: {connection_str:?}");
    println!("Timeout: {timeout:?}");
    println!("Pool size: {pool_size:?}");
}

fn main() {
    // Initialize the Database with the three structs
    let mut db = Database {
        connection_string: ConnectionString("localhost".to_string()),
        timeout: Timeout(30),
        pool_size: PoolSize(100),
    };

    let connection_string = &mut db.connection_string;
    print_database(connection_string.clone(), db.timeout, db.pool_size);
    *connection_string = ConnectionString("new string".to_string());
}
```

## แรงจูงใจ

แพตเทิร์นนี้มีประโยชน์สูงสุดเมื่อคุณมี struct ที่สะสมฟิลด์ข้อมูลไว้จำนวนมากเกินไป และคุณต้องการยืมฟิลด์เหล่านั้นแยกจากกันอย่างเป็นอิสระ เพื่อให้ระบบมีความยืดหยุ่นในการทำงานมากยิ่งขึ้น

## ข้อดี

การแยก struct ช่วยให้เราสามารถก้าวข้ามข้อจำกัดบางประการของ borrow checker ได้อย่างปลอดภัย และบ่อยครั้งยังส่งผลให้โครงสร้างการออกแบบของระบบมีความสะอาดและชัดเจนขึ้น

## ข้อเสีย

อาจทำให้โค้ดมีความยาวและต้องประกาศชนิดข้อมูลย่อยเพิ่มขึ้น และในบางกรณี struct ย่อยเหล่านั้นอาจไม่ได้เป็นตัวแทนเชิงนามธรรมที่ดีพอ ซึ่งจะส่งผลให้การออกแบบโดยรวมด้อยลง ซึ่งสถานการณ์ดังกล่าวถือเป็นสัญญาณเตือน (code smell) ที่บ่งชี้ว่าโครงสร้างของโปรแกรมอาจจำเป็นต้องได้รับการรีแฟกเตอร์ในมุมมองอื่นแทน

## การอภิปราย

แพตเทิร์นนี้ไม่จำเป็นสำหรับภาษาโปรแกรมที่ไม่มีระบบ borrow checker จึงถือเป็นแพตเทิร์นที่มีความเฉพาะตัวอย่างยิ่งในภาษา Rust อย่างไรก็ดี การแบ่งย่อยระบบออกเป็นหน่วยการทำงานขนาดเล็กยังคงนำไปสู่โค้ดที่สะอาดและดูแลรักษาง่ายกว่าเสมอ ซึ่งสอดคล้องกับหลักวิศวกรรมซอฟต์แวร์สากลโดยไม่ขึ้นกับภาษาใดๆ

ความสำเร็จของแพตเทิร์นนี้พึ่งพาความสามารถของ borrow checker ในภาษา Rust ที่สามารถตรวจสอบการยืมฟิลด์แต่ละตัวแยกจากกันได้อย่างเป็นอิสระ ในตัวอย่างข้างต้น borrow checker รับรู้ได้อย่างถูกต้องว่า `a.b` กับ `a.c` เป็นคนละส่วนกันและสามารถถูกยืมแยกกันได้ โดยไม่ได้เหมาล็อกทั้งก้อนของ `a` ซึ่งหากทำเช่นนั้น แพตเทิร์นนี้จะใช้งานไม่ได้ผล
