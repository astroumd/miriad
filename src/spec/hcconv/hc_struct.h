
typedef struct hc_struct {
    char *name ;
    char *type ;
    int length ;
    int *I_data ;
    char *C_data ;
    float *R_data ;
    double *D_data ;
    struct hc_struct *lo ;
    struct hc_struct *hi ;
    } HC_STRUCT ;

#define HC_NULL	(HC_STRUCT *) 0

HC_STRUCT *root = HC_NULL ;


