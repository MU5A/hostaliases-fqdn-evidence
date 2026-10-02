import java.net.InetAddress;

public class Probe {
    public static void main(String[] args) {
        for (String n : args) {
            String r;
            try { r = InetAddress.getAllByName(n)[0].getHostAddress(); }
            catch (Exception e) { r = "MISS"; }
            System.out.printf("    query %-20s java InetAddress=%s%n", "\"" + n + "\"", r);
        }
    }
}
