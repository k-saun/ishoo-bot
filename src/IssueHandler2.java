// Read a File using Scanner Class 
import java.io.*; 
import java.util.*; 
import java.io.File; 
import java.util.Scanner; 
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Paths;

public class IssueHandler2 
{
  public static String genBugReport(
  String filename, String currentDir, String repoName, String repoOwner, String token) 
  throws FileNotFoundException 
  { 
    
    //method to generate bug report
    File file = new File(currentDir + "/" + filename);
    Scanner sc = new Scanner(file); 

    //format the config file
    String textFromFile;
    String bugReport = "#Github Repo Access Config\nGithub:\n  UserInfo:\n";   
    bugReport = bugReport + "    repoOwner: " + "'" + repoOwner + "'\n    " + "repoName: '" + repoName + "'\n    " + "token: " +  token + "\n";   
    bugReport = bugReport + "  IssueReport:\n";

    while (sc.hasNextLine()) 
    {
      textFromFile = sc.nextLine();

      if(textFromFile.contains("TODO")) //find the TODO flag
      {  
	 //find title
     	 String title = "title: \"";
	 textFromFile = sc.nextLine();

	 while(!textFromFile.contains("-")) // get text until -
	 {
 		title = title + textFromFile + " ";
		textFromFile = sc.nextLine().trim();
	 }
	 title = title + "\"";
// 	 System.out.println(title); //print the title

	 textFromFile = sc.nextLine();

	 //find body of issue report
	 String body = "body: \"";
	 while(!textFromFile.contains("-")) // get text until -
	 {
 		body = body + textFromFile + " ";
		textFromFile = sc.nextLine().trim();
	 }
	 body = body + "\"";

 //	 System.out.println(body); //print the body

	 textFromFile = sc.nextLine();

	 //find bug of issue report
	 String bug = "bug: \"";
	 while(!textFromFile.contains("-")) // get text until -
	 {
 		bug = bug + textFromFile + ", ";
		textFromFile = sc.nextLine().trim();
	 }
         bug = bug + "\"";
//	 System.out.println(bug); //print bug label
	 bugReport = bugReport + "    " + title + "\n    " + body + "\n    " + bug + "";
	 

         title = " ";	
         body = " ";	
         bug = " ";	
         System.out.println("Config file built!\n.........................................................");
      }
    }
    return bugReport;
  }	 

  private static void writeUsingFiles(String data, String configDest) 
  {
        try {
            Files.write(Paths.get(configDest), data.getBytes());
        } catch (IOException e) {
            e.printStackTrace();
        }
  }


  public static void main(String[] args) throws Exception 
  { 
    Scanner userInput = new Scanner(System.in);
    String repoOwner;
    String repoName;
    String token;
    String fileName;


    System.out.println("Enter Repository Owner's Name");
    repoOwner = userInput.nextLine();

    System.out.println("Enter Name of Repository");
    repoName = userInput.nextLine();
    System.out.println("Enter Authorization Token");
    token = userInput.nextLine();

    System.out.println("Enter File to Parse");
    fileName = userInput.nextLine();

    // pass the path to the file as a parameter 
    
    String currentDir = System.getProperty("user.dir");
	 
    String configFile = currentDir + "/config.yaml";
    String bugReport = genBugReport(fileName, currentDir, repoName, repoOwner, token);
 
    writeUsingFiles(bugReport, configFile);

   } 
} 

