/* Acceptable access modes */

#define ACCESS_FTP "FTP"
#define ACCESS_HTTP "HTTP"

/* Things the libwww needs set */
char *HTAppName = "Get-url";
char *HTAppVersion = "1.0";
char *styleSheet = NULL;

/* function prototypes */
int handle_http();
