/* gr_iso.h
*/

extern char **td_Alloc2D();
extern void triangTetra();
extern void mcubeOneValue();
extern void triangCube();

typedef	struct {
	int	good;	/* non-zero if value has been set */
	float32	x, y, z;
	} InterpCoor;
			
typedef	struct {
	InterpCoor	h;	/* horizontal */
	InterpCoor	v;	/* vertical */
	InterpCoor	d;	/* diagonal, either / or \, but not both */
	} InterpData;
