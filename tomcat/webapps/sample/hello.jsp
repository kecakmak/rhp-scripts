<html>
<head>
<title>Sample Application JSP Page</title>
</head>
<body bgcolor=white>

<table border="0">
<tr>
<td align=center>
<img src="images/tomcat.gif">
</td>
<td>
<h1>Sample Application JSP Page</h1>
This is the output of a JSP page that is part of the Hello, World
application.
</td>
</tr>
</table>

<%= new String("Hello!") %>

      <ul>
         <li><p><b>First Name:</b>
            <%= request.getParameter("projectName")%>
         </p></li>
         <li><p><b>Last  Name:</b>
            <%= request.getParameter("last_name")%>
         </p></li>
      </ul>

</body>
</html>
