#ifdef linux
/* call fortran */
#define plot_setting_(a,ia,b,ib,flag) plot_setting__(a,ia,b,ib,flag) 
#define read_write_(a,ia,b,ib,flag) read_write__(a,ia,b,ib,flag)
#define save_posvel_() save_posvel__()
#define posvel_cuts_(a,la,b,lb,n,flag) posvel_cuts__(a,la,b,lb,n,flag) 
#define get_cuts_() get_cuts__()
#define overplo_tc_(cmap,clear) overplo_tc__(cmap,clear)
#define animate_w_(func,currentmap) animate_w__(func,currentmap)
#define set_stepcuts_(x,y,step,along,pa,n) set_stepcuts__(x,y,step,along,pa,n) 
#define set_rotatecuts_(x,y,SPa,dPa,n) set_rotatecuts__(x,y,SPa,dPa,n)
/* called by fortran */
#define check_overplot_(lm) check_overplot__(lm) 
#define entry_cuts_(ai,cuts_e,iflag) entry_cuts__(ai,cuts_e,iflag)
#define show_tool_(s) show_tool__(s)
#define main_vel_() main_vel__()
#define wrong_input_(s,index) wrong_input__(s,index)
#define save_posvel_() save_posvel__()
#endif

#define whitespace(c) (((c) == ' ') || ((c) == '\t'))

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#define MIN(a,b)     ((a) <= (b) ? (a) : (b))
#define MAX(a,b)   ((a) >= (b) ? (a) : (b))
#include "forms.h"

char *stripwhite ();

FL_FORM   *main_form, *conflag_form, *print_form, *cuts_form;
FL_FORM   *stepcut_form, *moment_form, *overplot_form;
FL_FORM   *rotatecut_form;
FL_OBJECT *current_group, *task, *subtask, *PosVel, *Implot;
FL_OBJECT *loadmap, *inputcut, *overplot, *s_posvel;
FL_OBJECT *next, *previous, *replot, *print, *defau, *close_q;
FL_OBJECT  *slider_page;
FL_OBJECT *close_c;
FL_OBJECT *plot_g, *animate_g;
FL_OBJECT *posvel_o[17], *implot_o[16], **taskobj;
char conflag_posvel[10], conflag_implot[10], *conflag_s;
int okay;
int quit=0;
const char *headdesc = "Velplot and Implot";
const char *version  = "Velplotc July 02 1999";

static void cb_input(FL_OBJECT *ob, long data)  ;
static void cb_choice(FL_OBJECT *ob, long data);
void cb_page(FL_OBJECT *obj,long arg);
static void show_group(FL_OBJECT *ob);
static void cb_task(FL_OBJECT *ob, long data);
void transfertofortran(char *, char *);
void cb_file(FL_OBJECT *ob, long  q);
static void passinformation();
static void settingConflag(char *);
static void cb_defau(FL_OBJECT *obj, long arg);
static void getconflagvalue();
static void cb_inputcut(FL_OBJECT *ob, long data);
void wrong_input_(char *s, char *index);

static void cb_input(FL_OBJECT *ob, long data)
{  const char *s = fl_get_input(ob);
   char r[35];
/* printf("CallBack: [%s][%s]\n", ob->label,s);
   printf("s: stringlen: [%d][%d]\n", strlen(ob->label),strlen(s)); */
   sprintf(r,"%s",stripwhite(s));
   fl_set_input(ob,r);
   transfertofortran(ob->label,r);
   return;
}

static void cb_choice(FL_OBJECT *ob, long data)
{  char r[35];
   strcpy(r,fl_get_choice_text(ob));
   transfertofortran(ob->label,r);
   return;
}

static void cb_button(FL_OBJECT *ob, long data)
{  int i;
   /* printf("class[%d][%d][%d]\n",FL_INPUT,FL_CHOICE,FL_BUTTON);*/
   if (!strcmp(ob->label,"Next")) {
     cb_page(slider_page,1);
   } else if (!strcmp(ob->label,"Prev")) {
     cb_page(slider_page,-1);
   } else if (!strcmp(ob->label,"Plot")) { 
     cb_page(slider_page,0);
   } else {
     passinformation();
     if (okay == 1) transfertofortran(ob->label,"button");
   }
   return;
}

static void show_group(FL_OBJECT *ob)
{ fl_hide_object(current_group);
  current_group=ob;
  fl_show_object(current_group);
  return;
}

static void cb_task(FL_OBJECT *ob, long data)
{  char r[35];
   strcpy(r,fl_get_choice_text(ob));
   /* printf("CallBack: [%s][%s]\n", ob->label,r); */
   if (!strcmp(r,"PosVel")) {
     show_group(PosVel);
     taskobj=posvel_o;
     conflag_s=conflag_posvel;
   }
   if (!strcmp(r,"Implot")) {
     show_group(Implot);
     taskobj=implot_o;
     conflag_s=conflag_implot;
   }
   transfertofortran(ob->label,r);
   return;
}

static void passinformation()
{  int i;
   okay=1;
   /* sending setting to main program */
   i=0;
   while(taskobj[i] != (FL_OBJECT *) NULL) {
    /* printf("KP0[%d]\n",i);*/
    /* printf("taskobj[%d][%s]\n",i,taskobj[i]->label);*/
    if (taskobj[i]->visible == 1 ) {
       if (!strcmp(taskobj[i]->label,"conflag")) getconflagvalue();
       if (taskobj[i]->objclass == FL_INPUT) cb_input(taskobj[i],0);
       if (taskobj[i]->objclass == FL_CHOICE) cb_choice(taskobj[i],0); 
       if (okay == 0) return; /* which means something wrong */
    }
    i=i++;
   };
   return;
}

void transfertofortran(char *a, char *b)
{ int ia, ib, flag;
  ia=strlen(a);
  ib=strlen(b);
  /*printf("--[%d][%s][%d][%s]\n",ia,a,ib,b);*/
  plot_setting_(a,&ia,b,&ib,&flag);
  okay=flag;
  return;
}

/* ***********Conflag form *************************************** */
int indexchar(char *s1,char *str)
{ int i;
  for (i=0;i<strlen(str);i++) {
    if (str[i] == s1[0]) return i;
  }
  return -1;
}

FL_OBJECT *conflag_obj[7],*close_c;
static void cb_close_c(FL_OBJECT *ob, long data)
{ int i;
  fl_hide_form(conflag_form);
  fl_activate_form(main_form);
  conflag_s[0]='\0';
  
  for (i=0;i<=6;i++) {
    if (fl_get_button(conflag_obj[i]) == 1) {
     sprintf(conflag_s,"%s%s",conflag_s,conflag_obj[i]->label);
    }
  }
  
  return;
}

static void getconflagvalue()
{ int i;
  char getconflag[10];
  strcpy(getconflag,conflag_s);
  transfertofortran("conflag",getconflag);
  return;
}

static void settingConflag(char *s)
{ int i,found;
 
  for (i=0;i<= 6;i++) {
    found = indexchar(conflag_obj[i]->label,s);
    if (found != -1) fl_set_button(conflag_obj[i], 1);
    else             fl_set_button(conflag_obj[i], 0);
  }
  return;
}

void create_conflag_form(void)
{ FL_OBJECT *obj;
  conflag_form = fl_bgn_form(FL_NO_BOX,50,180);
  fl_add_box(FL_FRAME_BOX,0,0,50,180,"");
  conflag_obj[0] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,10,45,15,"p");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[1] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,30,45,15,"a");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[2] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,50,45,15,"i");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[3] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,70,45,15,"n");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[4] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,90,45,15,"g");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[5] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,110,45,15,"t");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  conflag_obj[6] = obj = fl_add_roundbutton(FL_PUSH_BUTTON,5,130,45,15,"m");
     fl_set_object_color(obj,FL_COL1,FL_RED);
  close_c = fl_add_button(FL_NORMAL_BUTTON,10,150,25,15,"Ok");
     fl_set_object_callback(close_c, cb_close_c,0);
     fl_set_object_boxtype(close_c,FL_FRAME_BOX);
  fl_end_form();
}

static void cb_conflag(FL_OBJECT *ob, long data)
{ fl_deactivate_form (main_form);
  settingConflag(conflag_s);
  /*printf("[%s]\n",ob->label);*/
  fl_show_form(conflag_form, FL_PLACE_MOUSE,FL_TRANSIENT,"conflag");
  return;
}

/*   ********* print_form ************************************/
static void cb_print_c(FL_OBJECT *ob, long data);
FL_OBJECT *print_o[7], *print_go, *print_cancel, *page, *format;
static void create_print_form(void)
{ FL_OBJECT *obj;
  print_form = fl_bgn_form(FL_NO_BOX,170,100);
  fl_add_box(FL_FRAME_BOX,0,0,170,100,"");
  obj = fl_add_labelframe(FL_ENGRAVED_FRAME,5,10,60,55,"Page");
     fl_set_object_bw(obj, -1);
  page = fl_bgn_group();
   print_o[0] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,5,15,20,32,"Current");
     fl_set_object_color(obj,FL_COL1,FL_RED);
     fl_set_object_bw(obj, -1);
     fl_set_button(obj,1);
   print_o[1] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,5,35,20,32,"All");
     fl_set_object_color(obj,FL_COL1,FL_RED);
     fl_set_object_bw(obj, -1);
  fl_end_group();   
  obj = fl_add_labelframe(FL_ENGRAVED_FRAME,75,10,90,55,"Device");
     fl_set_object_bw(obj, -1);
  format = fl_bgn_group();
   print_o[2] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,75,15,20,32,"ps");
     fl_set_object_color(obj,FL_COL1,FL_GREEN);
     fl_set_object_bw(obj, -1);
     fl_set_button(obj,1);
   print_o[3] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,75,35,20,32,"vps");
     fl_set_object_color(obj,FL_COL1,FL_GREEN);
     fl_set_object_bw(obj, -1);
   print_o[4] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,115,15,20,32,"cps");
     fl_set_object_color(obj,FL_COL1,FL_GREEN);
     fl_set_object_bw(obj, -1);
   print_o[5] = obj = fl_add_checkbutton(FL_RADIO_BUTTON,115,35,20,32,"vcps");
     fl_set_object_color(obj,FL_COL1,FL_GREEN);
     fl_set_object_bw(obj, -1);
  fl_end_group();
  print_go = fl_add_button(FL_NORMAL_BUTTON,10,75,45,15,"Print");
     fl_set_object_callback(print_go, cb_print_c,1);
     fl_set_object_boxtype(print_go,FL_FRAME_BOX);
  print_cancel = fl_add_button(FL_NORMAL_BUTTON,100,75,45,15,"Cancel");
     fl_set_object_callback(print_cancel, cb_print_c,0);
     fl_set_object_boxtype(print_cancel,FL_FRAME_BOX);
  fl_end_form();
}

static void cb_print(FL_OBJECT *ob, long data)
{ fl_deactivate_form (main_form);
  fl_show_form(print_form, FL_PLACE_MOUSE,FL_TRANSIENT,"Print Panel");
  return;
}

static void cb_print_c(FL_OBJECT *ob, long data)
{ char command[10];
  int i;
  fl_hide_form(print_form);
  fl_activate_form(main_form);
  if (data != 1) return; /* cancel */
  command[0]='\0';
  for (i=0;i<=5;i++) {
    sprintf(command,"%s%d",command,fl_get_button(print_o[i]));
  }
  passinformation();
  if (okay == 1 ) transfertofortran("Print",command);
  return;
}

/******** stepcut_form **********************************************/
FL_OBJECT *step_obj[6];
void cb_close_stepcut(FL_OBJECT *obj, long arg)
{ int i,n;
  float x,y,step,along,pa;
  fl_hide_form(stepcut_form);
  fl_activate_form (cuts_form);
  if ( arg == 1 ) return;  /* cancel */
  x=atof(fl_get_input(step_obj[0]));
  y=atof(fl_get_input(step_obj[1]));
  step=atof(fl_get_input(step_obj[2]));
  along=atof(fl_get_input(step_obj[3]));
  pa=atof(fl_get_input(step_obj[4]));
  n=atoi(fl_get_input(step_obj[5]));
  /* printf("[%f][%f][%f][%f][%f][%d]\n",x,y,step,along,pa,n);*/
  set_stepcuts_(&x,&y,&step,&along,&pa,&n);
  return;
}  

void create_stepcut_form(void)
{ FL_OBJECT *obj;
  stepcut_form = fl_bgn_form(FL_UP_BOX,340,110);
  obj = fl_add_text(FL_NORMAL_TEXT,10,5,320,20,"Start at x, y and step"
   " along Angle for N steps.");
   fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
   fl_set_object_lcol(obj, FL_YELLOW);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  step_obj[0] =obj = fl_add_input(FL_FLOAT_INPUT,10,50,60,25,"x(\")");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  step_obj[1] = obj = fl_add_input(FL_FLOAT_INPUT,70,50,60,25,"y(\")");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  step_obj[2] = obj = fl_add_input(FL_FLOAT_INPUT,130,50,50,25,"step(\")");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
   fl_set_input(obj,"10");
  step_obj[3] = obj = fl_add_input(FL_FLOAT_INPUT,180,50,60,25,"along(deg)");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  step_obj[4] = obj = fl_add_input(FL_FLOAT_INPUT,240,50,50,25,"pa(deg)");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
   fl_set_input(obj,"90.0");
  step_obj[5] = obj = fl_add_input(FL_FLOAT_INPUT,290,50,35,25,"N");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
   fl_set_input(obj,"10");
  obj = fl_add_button(FL_NORMAL_INPUT,220,80,40,20,"Ok");
   fl_set_object_callback(obj, cb_close_stepcut,0);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_INPUT,270,80,40,20,"Cancel");
   fl_set_object_callback(obj, cb_close_stepcut,1);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_end_form();
}

/******** rotatecut_form **********************************************/
FL_OBJECT *rotate_obj[5];
void cb_close_rotatecut(FL_OBJECT *obj, long arg)
{ int i,n;
  float x,y,SPa,dPa;
  fl_hide_form(rotatecut_form);
  fl_activate_form (cuts_form);
  if ( arg == 1 ) return;  /* cancel */
  x=atof(fl_get_input(rotate_obj[0]));
  y=atof(fl_get_input(rotate_obj[1]));
  SPa=atof(fl_get_input(rotate_obj[2]));
  dPa=atof(fl_get_input(rotate_obj[3]));
  n=atoi(fl_get_input(rotate_obj[4]));
  /* printf("rotate[%f][%f][%f][%f][%d]\n",x,y,SPa,dPa,n); */
  set_rotatecuts_(&x,&y,&SPa,&dPa,&n);
  return;
}  

void create_rotatecut_form(void)
{ FL_OBJECT *obj;
  rotatecut_form = fl_bgn_form(FL_UP_BOX,340,110);
  obj = fl_add_text(FL_NORMAL_TEXT,10,5,320,20,"Center at x, y, Pa starts at"
   " SPa with step size of dPa for N steps.");
   fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
   fl_set_object_lcol(obj, FL_YELLOW);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  rotate_obj[0] =obj = fl_add_input(FL_FLOAT_INPUT,10,50,60,25,"x(\")");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  rotate_obj[1] = obj = fl_add_input(FL_FLOAT_INPUT,70,50,60,25,"y(\")");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  rotate_obj[2] = obj = fl_add_input(FL_FLOAT_INPUT,130,50,50,25,"SPa(deg)");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
  rotate_obj[3] = obj = fl_add_input(FL_FLOAT_INPUT,180,50,60,25,"dPa(deg)");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
   fl_set_input(obj,"10");
  rotate_obj[4] = obj = fl_add_input(FL_FLOAT_INPUT,240,50,55,25,"N");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
   fl_set_input(obj,"10");
  obj = fl_add_button(FL_NORMAL_INPUT,220,80,40,20,"Ok");
   fl_set_object_callback(obj, cb_close_rotatecut,0);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_INPUT,270,80,40,20,"Cancel");
   fl_set_object_callback(obj, cb_close_rotatecut,1);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_end_form();
}

/******** moment_form **********************************************/
FL_OBJECT *moment_o[5];
void cb_close_moment(FL_OBJECT *obj, long arg)
{ int i,n,ir,im,ic;
  char reg[50],clip[20],mom[3],out[20],in[20],command[100];
  fl_hide_form(moment_form);
  fl_activate_form (cuts_form);
  if (arg == 1 ) return;
  strcpy(command,"moment");
  strcpy(in,fl_get_input(moment_o[0]));
  strcpy(out,fl_get_input(moment_o[1]));
  strcpy(reg,fl_get_input(moment_o[2]));
  strcpy(mom,fl_get_input(moment_o[3]));
  strcpy(clip,fl_get_input(moment_o[4]));
  if (strlen(out) == 0 || strlen(in) == 0) { 
   wrong_input_("Must specific input and output name","0");
   return;
  }
  else {
    sprintf(command,"%s in=%s out=%s",command,in,out);
  }
  if (strlen(reg) != 0 ) sprintf(command,"%s region=%s",command,reg);
  if (strlen(mom) != 0 ) sprintf(command,"%s mom=%s",command,mom);
  if (strlen(clip) != 0 ) sprintf(command,"%s clip=%s",command,clip);
  system(command);
  printf("Complete ...\n");
  return;
}  

void cb_moment(FL_OBJECT *obj, long arg)
{ fl_deactivate_form(cuts_form); 
  fl_show_form(moment_form,FL_PLACE_MOUSE,FL_FULLBORDER,"Moment");
  return;
}  

void create_moment_form(void)
{ FL_OBJECT *obj;
  moment_form = fl_bgn_form(FL_UP_BOX,320,110);
  obj = fl_add_text(FL_NORMAL_TEXT,10,7,300,20,"Create Moment maps. Use "
   "overplot to see it.");
   fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
   fl_set_object_lcol(obj, FL_YELLOW);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  moment_o[0] = obj = fl_add_input(FL_NORMAL_INPUT,25,35,95,20,"in");
    fl_set_object_bw(obj, -2);
  moment_o[1] = obj = fl_add_input(FL_NORMAL_INPUT,145,35,95,20,"out");
    fl_set_object_bw(obj, -2);
  obj = fl_add_button(FL_NORMAL_INPUT,245,35,20,20,"Ok");
   fl_set_object_callback(obj, cb_close_moment,0);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_INPUT,270,35,30,20,"Close");
   fl_set_object_callback(obj, cb_close_moment,1);
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
  moment_o[2] =obj = fl_add_input(FL_NORMAL_INPUT,20,75,170,20,"region");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
    fl_set_object_bw(obj, -2);
  moment_o[3] = obj = fl_add_input(FL_FLOAT_INPUT,190,75,40,20,"mom");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
    fl_set_object_bw(obj, -2);
   fl_set_input(obj,"0");
  moment_o[4] = obj = fl_add_input(FL_NORMAL_INPUT,230,75,70,20,"clip");
   fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
    fl_set_object_bw(obj, -2);
   fl_set_input(obj,"0");
  fl_end_form();
}
/* ****** animate_form **********************************************/
FL_OBJECT *slider_ani,*slider_map,*close_ani;
int func,map_num,currentmap;
float speed=0.9;
void animate_work()
{ int tmpnum,tfunc,timages;
  /*printf("func=[%d]speed[%f]\n",func,speed);*/
  /* check the total number of maps everytime if it changes*/
  numberimages_(&timages);
  /*printf("newnumber=[%d]\n",timages);*/
  if (map_num != timages) {
    map_num=timages;
    fl_set_slider_bounds(slider_map,1.0, (double) map_num);
    currentmap=1;
    fl_set_slider_value(slider_map,(double) currentmap);
    func=9;
  }
  if (func == 9) { /* restart the animation with new setting */
      tfunc=10;
      /* printf("func=[%d]currentmap[%d]\n",func,currentmap); */
      animate_w_(&tfunc,&currentmap);    /* stop the animation */
      passinformation();
      transfertofortran("Animat","button");/* start again */
      func=3;
  }
  if (func == 0) return;
  if (func == 3 ) tmpnum=currentmap;
  if (func == -1 || func == -2 ) tmpnum=currentmap-1;
  if (func ==  1 || func ==  2 ) tmpnum=currentmap+1;
  if (tmpnum > map_num || tmpnum < 1) {
    func=0;
    return;
  }
  currentmap=tmpnum;
  fl_set_slider_value(slider_map,(double) currentmap);
  animate_w_(&func,&currentmap);
  if (func == 2 || func == -2 || func == 3) func=0;
  fl_msleep((long) ((1.0-speed)*500.0));
  return;
}

void cb_animate(FL_OBJECT *obj, long arg)
{ float speed;
  FL_OBJECT *ob;
  int domore=1;
  numberimages_(&map_num); /* obtain the total number of maps */
  func=2;
  currentmap=0;
  if (map_num <= 1) {
    fl_ringbell(20);
    fl_show_messages("Map number must be grater than 1");
    return;
  }
  passinformation();
  transfertofortran("Animat","button");
  fl_set_slider_bounds(slider_map,1.0, (double) map_num);
  fl_set_slider_value(slider_map,1.0);
  fl_deactivate_object(inputcut);
  fl_deactivate_object(overplot);
  while(domore) {
      ob = fl_check_forms();
      if (ob == close_q ) {domore=0; quit=1;}
      if (fl_get_choice(subtask) != 2) domore=0;
      animate_work();
  }

  func=10;
  animate_w_(&func,&currentmap);    /* stop the animation */
  fl_activate_object(inputcut);
  fl_activate_object(overplot);
  return;
}

void cb_animate_w(FL_OBJECT *obj, long arg)
{ if (arg == 3 ) currentmap = (int) fl_get_slider_value(obj);
  func=arg;
  /*printf("cb_animate_w:func=[%d]speed[%f]\n",func,speed);*/
  return;
}

void cb_speed(FL_OBJECT *obj, long arg)
{ speed = (float) fl_get_slider_value(obj);
  return;
}

/* ****** overplot_form *********************************************/
FL_OBJECT *overplot_o[12], *close_over, *do_overplot, *plotnum[4],*map_yes[4];
FL_OBJECT *map_o[4],*image_o[4],*contour_o[4],*conargs_o[4],*conflag_o[4];
void cb_overplot(FL_OBJECT *obj, long arg)
{ fl_show_form(overplot_form,FL_PLACE_MOUSE,FL_FULLBORDER,"Overplot");
  fl_deactivate_object(inputcut);
  fl_deactivate_object(overplot);
  fl_deactivate_object(next);
  fl_deactivate_object(previous);
  fl_deactivate_object(replot);
  fl_deactivate_object(print);
  return;
}

#include <dirent.h>
void checkdir_(char *s, int *flag)
{ DIR *fdir;
  *flag=1;
  /* printf("checkingdir[%s]\n",s); */
  fdir=opendir(s);
  if (fdir == NULL) *flag=0;
  closedir(fdir);
  return;
}

void checkmap_(const char *dire)
{ int lens=strlen(dire);
  char ldir[50],*s;
  char mesg[50];
  int direxist;
  strcpy(ldir,dire);
  s=ldir;
  s=s++;
  if (dire[0] != '!') return;
  checkdir_(s,&direxist);
  if (direxist == 0) {
   okay=0;
   sprintf(mesg,"Sorry ! No Map %s",s);
   wrong_input_(mesg,"0");
  }
  return;
}

void cb_do_overplot(FL_OBJECT *obj, long arg)
{ int clear=0,i,lm,ID;
  char r[20],cmap[20];
  cb_button(overplot, 0);
  okay=1;
  for (i=0;i<=3;i++) {
    sprintf(cmap,"%s",stripwhite(fl_get_input(map_o[i])));
    lm=strlen(cmap);
    if (lm != 0 && fl_get_button(map_yes[i]) == 1) checkmap_(cmap); /* exist ? */
    if (okay == 0 ) return; 
  }
  for (i=0;i<=3;i++) {
    sprintf(cmap,"%s",stripwhite(fl_get_input(map_o[i])));
    lm=strlen(cmap);
    if (lm != 0 && fl_get_button(map_yes[i]) == 1) {
      if (clear == 0) {
         if (arg == 1) clear=-99; /* print */
         overplo_tc_(cmap,&clear);
         clear=1;
      }
      strcpy(r,fl_get_choice_text(image_o[i]));
      transfertofortran(image_o[i]->label,r);
      if (fl_get_button(contour_o[i]) == 1) {
        transfertofortran("Contour","1"); }
      else {
        transfertofortran("Contour","0"); }
      sprintf(r,"%s",stripwhite(fl_get_input(conargs_o[i])));
      transfertofortran(conargs_o[i]->label,r);
      if (okay == 0 ) break;  /* skip it */
      sprintf(r,"%s",stripwhite(fl_get_input(conflag_o[i])));
      transfertofortran(conflag_o[i]->label,r);
      if (okay == 0 ) break;  /* skip it */
      overplo_tc_(cmap,&lm);
    }
  }
  if (clear == 1 && arg == 1 ) {
    clear=99; /* close print */
    overplo_tc_(cmap,&clear);
  }
  return;
}

void  check_overplot_(int *lm)
{ if (overplot_form->visible) {
    cb_do_overplot(do_overplot,0);
    *lm=1;
  }
  return;
}

void cb_close_overplot(FL_OBJECT *obj, long arg)
{ fl_hide_form(overplot_form);
  fl_activate_form(main_form);
  fl_activate_object(inputcut);
  fl_activate_object(overplot);
  fl_activate_object(next);
  fl_activate_object(previous);
  fl_activate_object(replot);
  fl_activate_object(print);
  return;
}  

void create_overplot_form(void)
{ FL_OBJECT *obj;
  int i;
  char imap[2];
  overplot_form = fl_bgn_form(FL_UP_BOX,320,380);
  obj = fl_add_text(FL_NORMAL_TEXT,20,10,280,40,"Overplot "
   "Different Maps In One Panel. Put '!' in front\n of the name means Get "
   "map from outside.");
  fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
  fl_set_object_lcol(obj, FL_YELLOW);
  fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  for (i=0;i<=3;i++) {
   sprintf(imap,"%d",i+1);
   obj = fl_add_labelframe(FL_ENGRAVED_FRAME,10,65+70*i,300,60,imap);
   plotnum[i]=fl_bgn_group();
   map_yes[i] = obj = fl_add_checkbutton(FL_PUSH_BUTTON,15,70+70*i,20,30,"");
   map_o[i] = obj = fl_add_input(FL_NORMAL_INPUT,70,75+70*i,140,20,"Map");
    fl_set_object_bw(obj, -1);
   image_o[i] = obj = fl_add_choice(FL_NORMAL_CHOICE,250,75+70*i,50,18,"Palette");
    fl_addto_choice(obj,"0|1|2|3|4|5|6|7|8|9|10|11|12");
   contour_o[i] = obj = fl_add_checkbutton(FL_PUSH_BUTTON,15,95+70*i,20,30,"");
   conargs_o[i] = obj = fl_add_input(FL_NORMAL_INPUT,85,100+70*i,120,20,"conargs");
    fl_set_object_bw(obj, -1);
    fl_set_input(obj,"10");
   conflag_o[i] = obj = fl_add_input(FL_NORMAL_INPUT,250,100+70*i,45,20,"conflag");
    fl_set_object_bw(obj, -1);
    fl_set_input(obj,"pn");
  fl_end_group();
  };
  do_overplot = obj = fl_add_button(FL_NORMAL_BUTTON,80,345,45,20,"Plot");
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_callback(obj,cb_do_overplot,0);
  obj = fl_add_button(FL_NORMAL_BUTTON,130,345,45,20,"Cuts");
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_callback(obj,cb_inputcut,0);
  do_overplot = obj = fl_add_button(FL_NORMAL_BUTTON,180,345,45,20,"Print");
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_callback(obj,cb_do_overplot,1);
  close_over = obj = fl_add_button(FL_NORMAL_BUTTON,230,345,45,20,"Close");
   fl_set_object_boxtype(obj,FL_FRAME_BOX);
   fl_set_object_callback(obj,cb_close_overplot,0);
  fl_end_form();
}

/* ****** cuts_form *************************************************/
FL_OBJECT *browser_cuts, *input_cuts, *close_cuts;
int n_b=0;

static void cb_cut_map(FL_OBJECT *ob, long data)
{ get_cuts_();
  return;
}

static void cb_inputcut(FL_OBJECT *ob, long data)
{ fl_show_form(cuts_form, FL_PLACE_MOUSE,FL_FULLBORDER,"Cuts Panel");
  return;
}

void sendcutstofortran(char *a, int n, char *b)
{ int la,lb, flag;
  la=strlen(a);
  lb=strlen(b);
  /*printf("[%d][%s][%d][%s]\n",la,a,lb,b); */
  okay=1;
  posvel_cuts_(a,&la,b,&lb,&n,&flag);
 if (flag == 0 ) okay=0;
 return;
}  

void entry_cuts_(char *ai, char *cuts_e, char *iflag)
{ int i=atoi(ai);
  int n_max=fl_get_browser_maxline(browser_cuts);
  /*printf("entry i=[%d],iflag=[%s],n=[%d]\n",i,iflag,n_max);*/
  if (i <= n_max ) {
   if (!strcmp(iflag,"R")) fl_replace_browser_line(browser_cuts,i,cuts_e);
   if (!strcmp(iflag,"D")) fl_delete_browser_line(browser_cuts,i);
   if (!strcmp(iflag,"C")) fl_clear_browser(browser_cuts); }
  else {
   fl_addto_browser(browser_cuts,cuts_e); }
}

void cb_input_cuts(FL_OBJECT *obj, long arg)
{  char r[30];
   char iflag[2]="A";
   int n_br=fl_get_browser_maxline(browser_cuts)+1;
  /* append and show the last line. Don't use this if you just want
   * to add some lines. use fl_add_browser_line
   */
  if (strcmp(fl_get_input(input_cuts)," ") <= 0) return;
  strcpy(r,fl_get_input(input_cuts));
  sendcutstofortran(r,n_br,iflag);
  if (okay == 1 ) fl_set_input(input_cuts,"");
}

void cb_replace_cuts(FL_OBJECT *obj, long arg)
{ char r[30];
  char iflag[2]="R";
  int n_br = fl_get_browser(browser_cuts);
  if (n_br == 0 ) return;
  strcpy(r,fl_get_input(input_cuts));
  if (strcmp(fl_get_input(input_cuts)," ") <= 0) return;
  sendcutstofortran(r,n_br,iflag);
  if (okay == 1 ) fl_set_input(input_cuts,"");
}

void cb_get_cuts(FL_OBJECT *obj, long arg)
{ int n_br = fl_get_browser(browser_cuts);
  const char *oup=fl_get_browser_line(browser_cuts,n_br);
  if (n_br == 0 || *oup == (char)NULL)  return;
  fl_set_input(input_cuts,oup);
}

void cb_delete_cuts(FL_OBJECT *obj, long arg)
{ char r[30];
  char iflag[2]="D";
  int n_br = fl_get_browser(browser_cuts);
  if (n_br == 0 ) return;
  strcpy(r,"0,0,0");
  sendcutstofortran(r,-n_br,iflag);
}

void cb_clear_cuts(FL_OBJECT *obj, long arg)
{ char r[30];
  char iflag[2]="C";
  int n_max=fl_get_browser_maxline(browser_cuts);
  int n=-99;
  if (n_max == 0 ) return;
  strcpy(r,"0,0,0");
  sendcutstofortran(r,n,iflag);
}

void cb_close_cuts(FL_OBJECT *obj, long arg)
{ fl_hide_form(cuts_form);
  return;
}  

void cb_step_cuts(FL_OBJECT *obj, long arg)
{ fl_deactivate_form(cuts_form);
  fl_show_form(stepcut_form,FL_PLACE_MOUSE,FL_FULLBORDER,"Stepcut");
  return;
}

void cb_rotate_cuts(FL_OBJECT *obj, long arg)
{ fl_deactivate_form(cuts_form);
  fl_show_form(rotatecut_form,FL_PLACE_MOUSE,FL_FULLBORDER,"Rotatecut");
  return;
}

void create_cuts_form(void)
{ FL_OBJECT *obj;
  cuts_form = fl_bgn_form(FL_UP_BOX,320,420);
  obj = fl_add_text(FL_NORMAL_TEXT,20,15,270,35,"Add cuts from "
   "File, Input, or Maps. Note: HR = - RA");
  fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
  fl_set_object_lcol(obj, FL_YELLOW);
  fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  browser_cuts = fl_add_browser(FL_HOLD_BROWSER,20,75,220,270,"List of cuts");
    fl_set_object_lalign(browser_cuts,FL_ALIGN_TOP_LEFT);
    fl_set_browser_fontstyle(browser_cuts, FL_FIXED_STYLE);
  input_cuts = obj = fl_add_input(FL_NORMAL_INPUT,20,370,200,25,"Input cut:"
   " HR(\"), DEC(\"), PA in degree (0..180)");
    fl_set_object_lalign(obj,FL_ALIGN_TOP_LEFT);
    fl_set_object_callback(obj,cb_input_cuts,0);
    fl_set_object_bw(obj, -1);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,75,50,25,"File");
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
    fl_set_object_callback(obj, cb_file, 0);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,105,50,25,"Map");
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
    fl_set_object_callback(obj, cb_cut_map, 0);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,135,50,25,"Replace");
    fl_set_object_callback(obj,cb_replace_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,165,50,25,"Getcut");
    fl_set_object_callback(obj,cb_get_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,195,50,25,"Delete");
    fl_set_object_callback(obj,cb_delete_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,225,50,25,"Clear");
    fl_set_object_callback(obj,cb_clear_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,255,50,25,"Stepcut");
    fl_set_object_callback(obj,cb_step_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,285,50,25,"Rotatecut");
    fl_set_object_callback(obj,cb_rotate_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,315,50,25,"Moment");
    fl_set_object_callback(obj,cb_moment,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  obj = fl_add_button(FL_NORMAL_BUTTON,250,345,50,25,"Close");
    fl_set_object_callback(obj,cb_close_cuts,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_end_form();
}

/*************** main_form ********************************************/

int pages=0;
void cb_page(FL_OBJECT *obj,long arg)
{ int tpages,currentpage;
  char pagestr[5];
  passinformation();
  if (okay == 1) {
    numberpages_(&tpages);
    currentpage = (int) fl_get_slider_value(obj);
    /*printf("tpages=[%d]\n",tpages);*/
    if (pages != tpages) {
      pages=tpages;
      fl_set_slider_bounds(obj,1.0, (double) tpages);
      fl_set_slider_value(slider_page,(double) 1.0);
    } else {
      currentpage = currentpage + arg;
      currentpage = MIN(MAX(1,currentpage),pages);
      fl_set_slider_value(slider_page,(double) currentpage);
    }
    currentpage = (int) fl_get_slider_value(obj);
    /*printf("currentpage=[%d]\n",currentpage);*/
    sprintf(pagestr,"%d",currentpage);
    transfertofortran("Slider",pagestr);
  }
  return;
}

void cb_subtask(FL_OBJECT *obj, long arg)
{ const char *choice=fl_get_choice_text(obj);
  if (!strcmp(choice,"Plot")) {
    fl_hide_object(animate_g);
    fl_show_object(plot_g);
  }
  if (!strcmp(choice,"Animate")) {
    fl_hide_object(plot_g);
    fl_show_object(animate_g);
    cb_animate(animate_g,0);
  }
  return;
}

void cb_s_posvel(FL_OBJECT *obj, long arg)
{ save_posvel_(); }

/* Note Here: We need a directory instead of a file */
void cb_loadmap(FL_OBJECT *obj, long arg)
{ const char *fname, *load();
  int lenfile;
  fname=load();
  if (fname != NULL) {
    /* printf("Load map %s\n",fname); */
    fname=fl_get_directory();
    /*printf("Load map %s\n",fname);*/
    lenfile=strlen(fname);
    readnewmap_(fname,&lenfile);
  }
}

void cb_check(FL_OBJECT *obj, long arg)
{ const char *s = fl_get_input(obj);
  int i,len=strlen(s);
  for (i=0;i<len;i++) {
    if ((s[i] <= '0' || s[i] >= '9') || s[i] == ',' || s[i] == '.') {
    } else {
      printf("Wrong input\n");
    }
     
  }
}

void create_main_form(void)
{ Pixmap p, mask;
  unsigned w,h;
  FL_OBJECT *obj;
  main_form = fl_bgn_form(FL_UP_BOX,240,385);
  obj = fl_add_text(FL_NORMAL_TEXT,5,5,230,15,headdesc);
  fl_set_object_color(obj,FL_INDIANRED,FL_PALEGREEN);
  fl_set_object_lcol(obj, FL_YELLOW);
  fl_set_object_boxtype(obj,FL_FRAME_BOX);
  fl_set_object_lalign(obj,FL_ALIGN_CENTER);
  task = fl_add_choice(FL_NORMAL_CHOICE,32,27,45,20,"Task");
   fl_set_object_callback(task,cb_task,0);
   fl_addto_choice(task,"PosVel|Implot");
  loadmap = obj = fl_add_button(FL_NORMAL_BUTTON,90,27,40,20,"Load");
   fl_set_object_boxtype(loadmap,FL_FRAME_BOX);
   fl_set_object_callback(loadmap,cb_loadmap,0);
  inputcut = obj = fl_add_button(FL_NORMAL_BUTTON,135,27,40,20,"Cuts");
   fl_set_object_boxtype(inputcut,FL_FRAME_BOX);
   fl_set_object_callback(inputcut,cb_inputcut,0);
  PosVel = fl_bgn_group();
   s_posvel = fl_add_button(FL_NORMAL_BUTTON,180,27,50,20,"Save");
     fl_set_object_callback(s_posvel,cb_s_posvel,0);
     fl_set_object_boxtype(s_posvel,FL_FRAME_BOX);
   posvel_o[0] = obj = fl_add_input(FL_FLOAT_INPUT,50,50,50,25,"Xmin");
     fl_set_object_bw(obj, -2);
   posvel_o[1] = obj = fl_add_input(FL_FLOAT_INPUT,145,50,50,25,"Xmax");
     fl_set_object_bw(obj, -2);
   posvel_o[2] = obj = fl_add_input(FL_FLOAT_INPUT,50,75,50,25,"Ymin");
     fl_set_object_bw(obj, -2);
   posvel_o[3] = obj = fl_add_input(FL_FLOAT_INPUT,145,75,50,25,"Ymax");
     fl_set_object_bw(obj, -2);
   posvel_o[4] = obj = fl_add_input(FL_NORMAL_INPUT,50,100,50,25,"nxy");
     fl_set_object_bw(obj, -2);
   posvel_o[5] = obj = fl_add_input(FL_NORMAL_INPUT,145,100,50,25,"Cbeam");
     fl_set_object_bw(obj, -2);
   posvel_o[6] = obj = fl_add_input(FL_NORMAL_INPUT,50,130,120,25,"conargs");
     fl_set_object_bw(obj, -2);
   posvel_o[7] = obj = fl_add_button(FL_NORMAL_BUTTON,170,130,50,23,"conflag");
    fl_set_object_callback(obj,cb_conflag,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
   posvel_o[8] = obj = fl_add_choice(FL_NORMAL_CHOICE,50,160,50,20,"Contour");
    fl_addto_choice(obj,"1|0");
   posvel_o[9] = obj = fl_add_choice(FL_NORMAL_CHOICE,145,160,60,20,"Box");
    fl_addto_choice(obj,"Untouch|Touch|Grid");
   posvel_o[10] = obj = fl_add_choice(FL_NORMAL_CHOICE,50,190,50,20,"Palette");
    fl_addto_choice(obj,"0|1|2|3|4|5|6|7|8|9|10|11|12");
   posvel_o[11] = obj = fl_add_input(FL_NORMAL_INPUT,145,190,70,25,"range");
     fl_set_object_bw(obj, -2);
   posvel_o[12] = obj = fl_add_input(FL_NORMAL_INPUT,145,220,70,25,"Data");
     fl_set_object_bw(obj, -2);
   posvel_o[13] = obj = fl_add_choice(FL_NORMAL_CHOICE,50,220,50,20,"Note");
    fl_addto_choice(obj,"1|0");
   posvel_o[14] = obj = fl_add_input(FL_NORMAL_INPUT,50,250,50,25,"Vrest");
     fl_set_object_bw(obj, -2);
   posvel_o[15] = obj = fl_add_input(FL_NORMAL_INPUT,145,250,70,25,"Cpos");
     fl_set_object_bw(obj, -2);
   posvel_o[16] = (FL_OBJECT *) NULL;
  fl_end_group();
  Implot = fl_bgn_group();
   overplot = fl_add_button(FL_NORMAL_BUTTON,180,27,50,20,"Overplot");
     fl_set_object_callback(overplot,cb_overplot,0);
     fl_set_object_boxtype(overplot,FL_FRAME_BOX);
   implot_o[0] = obj = fl_add_input(FL_FLOAT_INPUT,50,50,50,25,"Xmin");
     fl_set_object_bw(obj, -2);
   implot_o[1] = obj = fl_add_input(FL_FLOAT_INPUT,145,50,50,25,"Xmax");
     fl_set_object_bw(obj, -2);
   implot_o[2] = obj = fl_add_input(FL_FLOAT_INPUT,50,75,50,25,"Ymin");
     fl_set_object_bw(obj, -2);
   implot_o[3] = obj = fl_add_input(FL_FLOAT_INPUT,145,75,50,25,"Ymax");
     fl_set_object_bw(obj, -2);
   implot_o[4] = obj = fl_add_input(FL_NORMAL_INPUT,50,100,50,25,"nxy");
     fl_set_object_bw(obj, -2);
   implot_o[5] = obj = fl_add_input(FL_NORMAL_INPUT,50,130,120,25,"conargs");
     fl_set_object_bw(obj, -2);
   implot_o[6] = obj = fl_add_button(FL_NORMAL_BUTTON,170,130,50,23,"conflag");
    fl_set_object_callback(obj,cb_conflag,0);
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
   implot_o[7] = obj = fl_add_choice(FL_NORMAL_CHOICE,60,160,50,20,"Contour");
    fl_addto_choice(obj,"1|0");
   implot_o[8] = obj = fl_add_choice(FL_NORMAL_CHOICE,150,160,60,20,"Box");
    fl_addto_choice(obj,"Square|Touch");
   implot_o[9] = obj = fl_add_choice(FL_NORMAL_CHOICE,60,190,50,20,"Palette");
    fl_addto_choice(obj,"0|1|2|3|4|5|6|7|8|9|10|11|12");
   implot_o[10] = obj = fl_add_input(FL_NORMAL_INPUT,150,190,70,25,"range");
     fl_set_object_bw(obj, -2);
   implot_o[11] = obj = fl_add_input(FL_NORMAL_INPUT,150,220,70,25,"Data");
     fl_set_object_bw(obj, -2);
   implot_o[12] = obj = fl_add_choice(FL_NORMAL_CHOICE,60,220,50,20,"Note");
    fl_addto_choice(obj,"1|0");
   implot_o[13] = obj = fl_add_choice(FL_NORMAL_CHOICE,150,250,50,20,"units");
    fl_addto_choice(obj,"p|s|a");
   implot_o[14] = obj = fl_add_choice(FL_NORMAL_CHOICE,60,250,50,20,"beamquad");
    fl_addto_choice(obj,"0|1|2|3|4");
   implot_o[15] = (FL_OBJECT *) NULL;
  fl_end_group();
  subtask = obj = fl_add_choice(FL_NORMAL_CHOICE,60,280,50,20,"SubTask");
    fl_set_object_boxtype(obj,FL_FRAME_BOX);
    fl_addto_choice(obj,"Plot|Animate");
    fl_set_object_callback(obj, cb_subtask,0);
  close_q = fl_add_button(FL_NORMAL_BUTTON,160,280,40,20,"Close");
    fl_set_object_boxtype(close_q,FL_FRAME_BOX);
  obj = fl_add_labelframe(FL_ENGRAVED_FRAME,15,305,210,65,"");
         fl_set_object_bw(obj, -1);
  plot_g = fl_bgn_group();
    next = fl_add_button(FL_NORMAL_BUTTON,30,310,50,25,"Next");
     fl_set_object_callback(next, cb_button,0);
     fl_set_object_boxtype(next,FL_FRAME_BOX);
    previous = fl_add_button(FL_NORMAL_BUTTON,95,310,50,25,"Prev");
     fl_set_object_callback(previous, cb_button,0);
     fl_set_object_boxtype(previous,FL_FRAME_BOX);
     replot = fl_add_button(FL_NORMAL_BUTTON,160,310,50,25,"Plot");
     fl_set_object_callback(replot, cb_button,0);
     fl_set_object_boxtype(replot,FL_FRAME_BOX);
     slider_page = fl_add_valslider(FL_HOR_NICE_SLIDER,45,340,100,25,"Page");
     fl_set_object_boxtype(slider_page,FL_FLAT_BOX);
     fl_set_object_lalign(slider_page,FL_ALIGN_LEFT);
     fl_set_slider_precision(slider_page,0);
     fl_set_slider_step(slider_page,1.0);
     fl_set_slider_return(slider_page,FL_RETURN_END);
     fl_set_object_callback(slider_page, cb_page,0);
     print = fl_add_button(FL_NORMAL_BUTTON,160,340,50,25,"Print");
     fl_set_object_callback(print, cb_print,0);
     fl_set_object_boxtype(print,FL_FRAME_BOX);
  fl_end_group();
  animate_g= fl_bgn_group();
    obj = fl_add_button(FL_NORMAL_BUTTON,30,310,30,25,"@#-2<<");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,-2);
    obj = fl_add_button(FL_NORMAL_BUTTON,60,310,30,25,"@#-2<|");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,-1);
    obj = fl_add_button(FL_NORMAL_BUTTON,90,310,30,25,"@#-2|>");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,1); 
    obj = fl_add_button(FL_NORMAL_BUTTON,120,310,30,25,"@#-2>>");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,2); 
    obj = fl_add_button(FL_NORMAL_BUTTON,150,310,30,25,"Stop");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,0);
    obj = fl_add_button(FL_NORMAL_BUTTON,180,310,30,25,"Reset");
     fl_set_object_boxtype(obj,FL_FRAME_BOX);
     fl_set_object_callback(obj,cb_animate_w,9);
    slider_ani = obj = fl_add_valslider(FL_HOR_NICE_SLIDER,50,340,70,25,"Speed");
     fl_set_object_boxtype(obj,FL_FLAT_BOX);
     fl_set_object_lalign(obj,FL_ALIGN_LEFT);
     fl_set_slider_value(obj,(double) speed);
     fl_set_object_callback(obj,cb_speed,0);
    slider_map = obj = fl_add_valslider(FL_HOR_NICE_SLIDER,140,340,80,25,"Map");
     fl_set_object_boxtype(obj,FL_FLAT_BOX);
     fl_set_object_lalign(obj,FL_ALIGN_LEFT);
     fl_set_slider_precision(obj,0);
     fl_set_slider_step(obj,1.0);
     fl_set_slider_return(obj,FL_RETURN_END);
     fl_set_object_callback(obj,cb_animate_w,3);
  fl_end_group();
  fl_hide_object(animate_g);
  fl_end_form();
  fl_hide_object(PosVel);
  fl_hide_object(Implot);
/*p = fl_read_pixmapfile(fl_root, "xconq.xpm", &w, &h, &mask, 0, 0, 0);
  fl_set_form_icon(main_form, p, mask); */
}

static void cb_defau(FL_OBJECT *obj, long arg)
{ int i;
  char *label,r[20];
  strcpy(r,fl_get_choice_text(task));
  i=0;
  while(taskobj[i] != (FL_OBJECT *) NULL) {
     label=taskobj[i]->label;
     /*printf("Hi task[%s]\n",label);*/
     if (!strcmp(label,"Xmin")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"Xmax")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"Ymin")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"Ymax")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"nxy")) fl_set_input(taskobj[i],"1,1");
     if (!strcmp(label,"Cbeam")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"range")) fl_set_input(taskobj[i],"");
     if (!strcmp(label,"conargs")) fl_set_input(taskobj[i],"10");
     if (!strcmp(label,"conflag")) {
      strcpy(conflag_s,"pn");
      settingConflag(conflag_s);
     }
     if (!strcmp(label,"Contour")) fl_set_choice_text(taskobj[i],"1");
     if (!strcmp(label,"Box")) {
       if (!strcmp(r,"PosVel")) fl_set_choice_text(taskobj[i],"Untouch");
       if (!strcmp(r,"Implot")) fl_set_choice_text(taskobj[i],"Square");
     }
     if (!strcmp(label,"Palette")) fl_set_choice_text(taskobj[i],"0");
     if (!strcmp(label,"Note")) fl_set_choice_text(taskobj[i],"1");
     if (!strcmp(label,"units")) fl_set_choice_text(taskobj[i],"s");
     if (!strcmp(label,"beamquad")) fl_set_choice_text(taskobj[i],"0");
   i=i++;
  }
  return;
}

/*
type=0 ==> fl_set_input
type=1 ==> fl_set_choice_text
type=2 ==> settingConflag
*/
int set_user(FL_OBJECT *obj,char *label, char *defau, int type)
{ int lenlabel;
  char valuestr[35];
  lenlabel=strlen(label);
  checkkeyword_(label,&lenlabel,valuestr);
  /*printf("Hi label[%s]=[%s]\n",label,valuestr);*/
  if (type == 0) {
    if (strlen(valuestr) > 0) fl_set_input(obj,valuestr);
    else 		      fl_set_input(obj,defau);
  }
  if (type == 1) {
    if (strlen(valuestr) > 0) fl_set_choice_text(obj,valuestr);
    else 		      fl_set_choice_text(obj,defau);
  }
  if (type == 2) {
    if (strlen(valuestr) > 0) strcpy(conflag_s,valuestr);
    else 		      strcpy(conflag_s,defau);
    settingConflag(conflag_s);
  }
}

static void cb_userrequest(FL_OBJECT *obj, long arg)
{ int i;
  char *label,r[20];
  strcpy(r,fl_get_choice_text(task));
  i=0;
  while(taskobj[i] != (FL_OBJECT *) NULL) {
     label=taskobj[i]->label;
     /*printf("Hi task[%s]\n",label);*/
     
     if (!strcmp(label,"Xmin")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"Xmax")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"Ymin")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"Ymax")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"nxy"))  set_user(taskobj[i],label,"1,1",0);
     if (!strcmp(label,"Cbeam")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"Vrest")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"range")) set_user(taskobj[i],label,"",0);
     if (!strcmp(label,"conargs")) set_user(taskobj[i],label,"10",0);
     if (!strcmp(label,"conflag")) set_user(taskobj[i],label,"pn",2);
     if (!strcmp(label,"Contour")) set_user(taskobj[i],label,"1",1);
     if (!strcmp(label,"Box")) {
       if (!strcmp(r,"PosVel")) fl_set_choice_text(taskobj[i],"Untouch");
       if (!strcmp(r,"Implot")) fl_set_choice_text(taskobj[i],"Square");
     }
     if (!strcmp(label,"Palette")) set_user(taskobj[i],label,"0",1);
     if (!strcmp(label,"Note")) set_user(taskobj[i],label,"1",1);
     if (!strcmp(label,"units")) set_user(taskobj[i],label,"s",1);
     if (!strcmp(label,"beamquad")) set_user(taskobj[i],label,"0",1);
   i=i++;
  }
  return;
}

/* ************************************************************** */
void main_vel_()
{ FL_OBJECT *obj;
  int argc;
  char *argv[2];
  argc=1;
  argv[0]="velplotc";
  fl_initialize(&argc, argv, "FormDemo", 0, 0);
  create_main_form();
  create_conflag_form();
  create_print_form();
  create_cuts_form();
  create_stepcut_form();
  create_rotatecut_form();
  create_moment_form();
  create_overplot_form();
  fl_set_choice_text(task,"PosVel");
  taskobj=posvel_o;
  conflag_s=conflag_posvel;
  cb_defau(task,0);
  fl_set_choice_text(task,"Implot");
  taskobj=implot_o;
  conflag_s=conflag_implot;
  cb_defau(task,0);
  return;
}

void show_tool_(char *s)
{ FL_OBJECT *obj;
  int numpage=0,tnumpage;
  
  /*printf("show_tool[%s]\n",s);*/
  /*s="Implot"; */
  if (!strcmp("PosVel",s)) current_group=PosVel;
  if (!strcmp("Implot",s)) current_group=Implot;
  /*printf("Current group[%s]\n",current_group->label); */
  transfertofortran("Task",s);
  fl_set_choice_text(task,s);
  cb_task(task,0);
  cb_userrequest(task,0);
  fl_show_form(main_form,FL_PLACE_HOTSPOT|FL_FREE_SIZE,FL_FULLBORDER,version);
  while(!quit ) {
    obj = fl_check_forms();
    if (obj == close_q ) quit=1;
  }

  fl_hide_form(main_form);
  return;
}

void wrong_input_(char *s, char *index)
{char str[80];
 fl_ringbell(20);
 /* printf("index=[%s]\n",index); */
 sprintf(str,"Wrong Input: %s.",s);
 fl_show_messages(str);
 if (index == "1" ) exit(1);
 return;
}

void warning_(char *s, char *index)
{char str[80];
 fl_ringbell(20);
 /* printf("index=[%s]\n",index); */
 sprintf(str,"Warning: %s.",s);
 fl_show_messages(str);
 if (index == "1" ) exit(1);
 return;
}

void ioreadsave(const char *a, const char *b)
{ int ia, ib, flag;
/*  char b[80];*/
  ia=strlen(a);
  ib=strlen(b);
  /* printf("[%d][%s][%d][%s]\n",ia,a,ib,b);*/
  read_write_(a,&ia,b,&ib,&flag);
  okay=flag;
  return;
}  

static int menu2 = -1;
void cb_file(FL_OBJECT *ob, long q)
{  const char *fname, *load(), *save();
   if (menu2==-1)
   {
   menu2 = fl_newpup(FL_ObjWin(ob));
   fl_addtopup(menu2,"Load%h","Ll#l");
   fl_addtopup(menu2,"Save%h","Ss#s");
   }
   if(fl_get_button_numb(ob) >= FL_SHORTCUT)
      fl_setpup_position(ob->form->x + ob->x,ob->form->y + ob->y + ob->h); 

   switch(fl_dopup(menu2))
   { case 1:
       fname=load();
       /* printf("%s\n",fname);*/
       if (fname != (char *)NULL ) ioreadsave("r",fname);
       break;
     case 2:
       fname=save();
       /* printf("%s\n",fname); */
       if (fname != (char *)NULL ) ioreadsave("s",fname);
       break;
   }    
}

const char *load()
{ const char *fname;
  fname = fl_show_file_selector("File To Load","","*","");
  if (fname == NULL) return NULL;
  return fname;
}

const char *save()
{ const char *fname;
  fname = fl_show_file_selector("File To Save","","*","");
  if (fname == NULL) return NULL;
  return fname;
}

char *stripwhite (char *string)
/* Strip whitespace from the start and end of STRING.  Return a pointer
   into STRING. */
{ register char *s, *t;
  for (s = string; whitespace (*s); s++);
  if (*s == 0) return (s);
  t = s + strlen (s) - 1;
  while (t > s && whitespace (*t)) t--;
  *++t = '\0';
  return s;
}
