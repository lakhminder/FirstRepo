import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;


public class Test {

	/**
	 * @param args
	 */
	/*public static void main(String[] args) {
		// TODO Auto-generated method stub
		String input1="CAPPGAFJLDHKDMJ";
		String input2="KDMJCAPPGAFJLDH";
		String input3="PGKDMPJCAAFJLDH";
		
		
		
		UserMainCode1.splitting_rows(input1, input2); 
		
	}*/
	
	public static void main(String[] args) {
		int rowCount = 5;
		Date date = new Date(2014, 3, 5, 0, 52);
		SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy-MM-dd kk:mm:ss");
		SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		
		System.out.println("Time value using kk:" + sdf1.format(date));
		System.out.println("Time Value using HH:" + sdf2.format(date));
		System.out.println(rowCount);
	}
		

}
