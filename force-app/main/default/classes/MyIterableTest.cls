@IsTest
public class MyIterableTest {
    @IsTest
    static void testIterableForLoop() {
        List<String> strings = new List<String>{ 'Hello', 'World' };
        MyIterable myIterable = new MyIterable(strings);

        for (String s : myIterable) {
            System.debug(s);
        }
    }
}