# การแยก struct เพื่อการยืมที่เป็นอิสระต่อกัน

## คำอธิบาย

บางครั้ง struct ขนาดใหญ่จะสร้างปัญหาให้กับ borrow checker - แม้ว่าฟิลด์ต่างๆ จะถูกยืมแยกกันได้ แต่บางครั้งทั้ง struct ก็ถูกใช้พร้อมกันทั้งหมดจนขัดขวางการใช้งานอื่น ทางออกหนึ่งคือแยก struct ออกเป็น struct เล็กๆ หลายตัว แล้วประกอบกลับเข้าเป็น struct เดิม จากนั้นแต่ละ struct ก็ถูกยืมแยกกันได้และมีพฤติกรรมที่ยืดหยุ่นขึ้น

วิธีนี้มักนำไปสู่การออกแบบที่ดีขึ้นในด้านอื่นด้วย: การใช้แพตเทิร์นการออกแบบนี้มักเผยให้เห็นหน่วยการทำงานที่เล็กลง

## ตัวอย่าง

นี่คือตัวอย่างสมมติที่ borrow checker ขัดขวางแผนการใช้ struct ของเรา:

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

คอมไพเลอร์จะโยนข้อผิดพลาดดังต่อไปนี้:

```ignore
let connection_string = &mut db.connection_string;
                        ------------------------- mutable borrow occurs here
print_database(&db);
               ^^^ immutable borrow occurs here
*connection_string = "new string".to_string();
------------------ mutable borrow later used here
```

เราสามารถนำแพตเทิร์นการออกแบบนี้มาใช้ และรีแฟกเตอร์ `Database` ให้เป็น struct เล็กๆ สามตัว ซึ่งแก้ปัญหาการตรวจสอบการยืมได้:

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

แพตเทิร์นนี้มีประโยชน์ที่สุดเมื่อคุณมี struct ที่ลงเอยด้วยฟิลด์จำนวนมากซึ่งคุณต้องการยืมแยกกัน จึงได้พฤติกรรมที่ยืดหยุ่นขึ้นในท้ายที่สุด

## ข้อดี

การแยก struct ช่วยให้คุณหลบเลี่ยงข้อจำกัดของ borrow checker ได้ และมักให้การออกแบบที่ดีขึ้นด้วย

## ข้อเสีย

อาจทำให้โค้ดยาวขึ้น และบางครั้ง struct เล็กๆ เหล่านั้นไม่ใช่นามธรรมที่ดี เราจึงได้การออกแบบที่แย่ลง นั่นคงเป็น 'code smell' ที่บ่งชี้ว่าโปรแกรมควรถูกรีแฟกเตอร์ในทางใดทางหนึ่ง

## การอภิปราย

แพตเทิร์นนี้ไม่จำเป็นในภาษาที่ไม่มี borrow checker ในแง่นั้นจึงเป็นเอกลักษณ์ของ Rust อย่างไรก็ตาม การสร้างหน่วยการทำงานที่เล็กลงมักนำไปสู่โค้ดที่สะอาดขึ้น: หลักการที่วิศวกรรมซอฟต์แวร์ยอมรับกันกว้างขวาง โดยไม่ขึ้นกับภาษา

แพตเทิร์นนี้อาศัย borrow checker ของ Rust ในการยืมฟิลด์แยกจากกัน ในตัวอย่าง borrow checker รู้ว่า `a.b` กับ `a.c` ต่างกันและยืมแยกกันได้ มันไม่ได้พยายามยืม `a` ทั้งก้อน ซึ่งถ้าเป็นเช่นนั้นแพตเทิร์นนี้ก็จะไร้ประโยชน์
