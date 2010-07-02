/* 
  mxTools -- Misc. utilities for Python

  Copyright (c) 1997-2000, Marc-Andre Lemburg; mailto:mal@lemburg.com
  Copyright (c) 2000-2008, eGenix.com Software GmbH; mailto:info@egenix.com
  See the documentation for further copyright information or contact
  the author (mailto:mal@lemburg.com).

*/

/* Define this to aid in finding memory leaks */
/*#define MAL_MEM_DEBUG*/
/*#define MAL_DEBUG*/
/*#define MAL_REF_DEBUG*/

/* Logging file used by debugging facility */
#ifndef MAL_DEBUG_OUTPUTFILE
# define MAL_DEBUG_OUTPUTFILE "mxTools.log"
#endif

/* We want all our symbols to be exported */
#define MX_BUILDING_MXTOOLS

/* Mark the module as Py_ssize_t clean. */
#define PY_SSIZE_T_CLEAN 1

#include "mx.h"
#include "mxTools.h"

/* Needed for mxTools_EvalCodeString() */
#include "compile.h"
#include "eval.h"

/* Needed for mxTools_cur_frame() */
#include "frameobject.h"

/* Needed for mxTools_dlopen() */
#ifdef HAVE_DLOPEN
# include <dlfcn.h>
#endif

#define MXTOOLS_VERSION "3.1.1"

/* To open up the playground for new ideas... */
/*#define INCLUDE_FUNSTUFF*/

/* Maximal size of the code cache used by mxTools_EvalCodeString() */
#define MAX_CODECACHE_SIZE	10

/* --- module doc-string -------------------------------------------------- */

static char *Module_docstring = 

 MXTOOLS_MODULE" -- A tool collection. Version "MXTOOLS_VERSION"\n\n"

 "Copyright (c) 1997-2000, Marc-Andre Lemburg; mailto:mal@lemburg.com\n"
 "Copyright (c) 2000-2008, eGenix.com Software GmbH; mailto:info@egenix.com\n\n"
 "                 All Rights Reserved\n\n"
 "See the documentation for further information on copyrights,\n"
 "or contact the author."
;

/* --- module globals ----------------------------------------------------- */

static PyObject *mxTools_Error;			/* Error Exception
						   object */

static PyObject *mxTools_ProgrammingError;	/* ProgrammingError Exception
						   object */

static PyObject *mxNotGiven;			/* NotGiven singleton */

static PyObject *mxTools_BaseobjAttribute;      /* Attribute to use for
						   acquire() per default */

/* Flag telling us whether the module was initialized or not. */
static int mxTools_Initialized = 0;

/* --- forward declarations ----------------------------------------------- */

/* --- internal macros ---------------------------------------------------- */

/* --- module helpers ----------------------------------------------------- */

/* Create an exception object, insert it into the module dictionary
   under the given name and return the object pointer; this is NULL in
   case an error occurred. */

static 
PyObject *insexc(PyObject *moddict,
		 char *name,
		 PyObject *baseclass)
{
    PyObject *v;
    char fullname[256];
    char *modname;
    char *dot;
    
    v = PyDict_GetItemString(moddict, "__name__");
    if (v == NULL)
	modname = NULL;
    else
	modname = PyString_AsString(v);
    if (modname == NULL) {
	PyErr_Clear();
	modname = MXTOOLS_MODULE;
    }
    /* The symbols from this extension are imported into
       mx.<packagename>. We trim the name to not confuse the user with
       an overly long package path. */
    strcpy(fullname, modname);
    dot = strchr(fullname, '.');
    if (dot)
	dot = strchr(dot+1, '.');
    if (dot)
	strcpy(dot+1, name);
    else
	sprintf(fullname, "%s.%s", modname, name);


    v = PyErr_NewException(fullname, baseclass, NULL);
    if (v == NULL)
	return NULL;
    if (PyDict_SetItemString(moddict,name,v))
	return NULL;
    return v;
}

#ifdef HAVE_DLOPEN
/* Helper for adding integer constants. Check for errors with
   PyErr_Occurred() */
static 
void insint(PyObject *dict,
	    char *name,
	    int value)
{
    PyObject *v = PyInt_FromLong((long)value);
    PyDict_SetItemString(dict, name, v);
    Py_XDECREF(v);
}
#endif

/* Helper for adding string constants to a dictionary. Check for
   errors with PyErr_Occurred() */
static 
void insstr(PyObject *dict,
	    char *name,
	    char *value)
{
    PyObject *v = PyString_FromString(value);
    PyDict_SetItemString(dict, name, v);
    Py_XDECREF(v);
}

static
PyObject *notimplemented1(PyObject *v)
{
    Py_Error(PyExc_TypeError,
	     "operation not implemented");
 onError:
    return NULL;
}

static
PyObject *notimplemented2(PyObject *v, PyObject *w)
{
    Py_Error(PyExc_TypeError,
	     "operation not implemented");
 onError:
    return NULL;
}

static
PyObject *notimplemented3(PyObject *u, PyObject *v, PyObject *w)
{
    Py_Error(PyExc_TypeError,
	     "operation not implemented");
 onError:
    return NULL;
}

/* --- Internal Functions ------------------------------------------------- */

#ifdef INCLUDE_FUNSTUFF
static
PyObject *mxTools_EvalCodeString(PyObject *codestr)
{
    static PyObject *codecache;
    PyObject *code;
    PyObject *v;
    
    Py_Assert(PyString_Check(codestr),
	      PyExc_SystemError,
	      "Bad internal call to mxTools_EvalCodeString");

    /* Init. codecache dictionary */
    if (codecache == NULL) {
	codecache = PyDict_New();
	if (!codecache)
	    goto onError;
    }
    
    /* Get code object or compile the string */
    code = PyDict_GetItem(codecache,codestr);
    if (!code) {
	code = Py_CompileString(PyString_AS_STRING(codestr),
				"<string>", Py_eval_input);
	if (!code)
	    goto onError;
	if (PyDict_Size(codecache) >= MAX_CODECACHE_SIZE)
	    PyDict_Clear(codecache);
	PyDict_SetItem(codecache,codestr,code);
    }
    else
	Py_INCREF(code);
    
    /* Run the code in the current context */
    v = PyEval_EvalCode((PyCodeObject *)code,
			PyEval_GetGlobals(),
			PyEval_GetLocals());
    Py_DECREF(code);
    return v;

 onError:
    return NULL;
}
#endif

/* --- Interface ---------------------------------------------------------- */

Py_C_Function( mxTools_napply,
	       "napply(number_of_calls,function,args=(),kw={})\n\n"
	       "Calls the function number_of_calls times with the same\n"
	       "arguments and returns a tuple with the return values.")
{
    Py_ssize_t count;
    register Py_ssize_t i;
    PyObject *func,*arg = 0,*kw = 0;
    PyObject *w = 0;

    Py_Get4Args(Py_SSIZE_T_PARSERMARKER
		"O|OO",
		count,func,arg,kw);

    Py_XINCREF(arg);

    w = PyTuple_New(count);
    if (w == NULL)
	goto onError;

    if (arg == NULL)
	arg = PyTuple_New(0);
    if (arg == NULL)
	goto onError;

#ifdef PyCFunction_GET_FUNCTION
    /* Short-cut for C functions, taken from ceval.c:call_builtin();
       Note: this only works and is used together with my patched
       version of the interpreter. XXX Update when ceval.c changes !!! */
    if (PyCFunction_Check(func)) {
	register PyCFunction meth = PyCFunction_GET_FUNCTION(func);
	register PyObject *self = PyCFunction_GET_SELF(func);
	int flags = PyCFunction_GET_FLAGS(func);

	if (!(flags & METH_VARARGS)) {
	    Py_ssize_t size = PyTuple_GET_SIZE(arg);
	    if (size == 1)
		arg = PyTuple_GET_ITEM(arg, 0);
	    else if (size == 0)
		arg = NULL;
	}
	if (flags & METH_KEYWORDS)
	    for (i = 0; i < count; i++) {
		register PyObject *v;
	    
		v = (*(PyCFunctionWithKeywords)meth)(self, arg, kw);
		if (v == NULL)
		    goto onError;
		PyTuple_SET_ITEM(w,i,v);
	    }
	else {
	    if (kw != NULL && PyDict_Size(kw) != 0) {
		PyErr_SetString(PyExc_TypeError,
				"this function takes no keyword arguments");
		return NULL;
	    }
	    for (i = 0; i < count; i++) {
		register PyObject *v;
	    
		v = (*meth)(self, arg);
		if (v == NULL)
		    goto onError;
		PyTuple_SET_ITEM(w,i,v);
	    }
	}
    }
    else
#endif
	for (i = 0; i < count; i++) {
	    register PyObject *v;
	    
	    v = PyEval_CallObjectWithKeywords(func,arg,kw);
	    if (v == NULL)
		goto onError;
	    PyTuple_SET_ITEM(w,i,v);
	}

    Py_XDECREF(arg);
    return w;

 onError:
    Py_XDECREF(w);
    Py_XDECREF(arg);
    return NULL;
}

Py_C_Function( mxTools_mapply,
	       "mapply(callable_objects,args=(),kw={})\n\n"
	       "Calls the callable_objects in the given order with the same\n"
	       "arguments and returns a tuple with the return values.")
{
    register Py_ssize_t i;
    Py_ssize_t n;
    PyObject *objects;
    PyObject *arg = 0,*kw = 0;
    PyObject *w = 0;

    Py_Get3Args("O|OO",
		objects,arg,kw);

    Py_XINCREF(arg);

    n = PySequence_Length(objects);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "first argument must be a sequence");

    w = PyTuple_New(n);
    if (w == NULL)
	goto onError;

    if (arg == NULL)
	arg = PyTuple_New(0);
    if (arg == NULL)
	goto onError;

    for (i = 0; i < n; i++) {
	register PyObject *func;
	func = PySequence_GetItem(objects,i);
	if (!func)
	    goto onError;
#ifdef PyCFunction_GET_FUNCTION
	/* Short-cut for C functions, taken from
	   ceval.c:call_builtin(); Note: this only works and is used
	   with my patched version of the interpreter. XXX Update when
	   ceval.c changes !!! */
	if (PyCFunction_Check(func)) {
	    PyObject *args = arg;
	    
	    if (!(PyCFunction_GET_FLAGS(func) & METH_VARARGS)) {
		Py_ssize_t size = PyTuple_GET_SIZE(args);
		if (size == 1)
		    args = PyTuple_GET_ITEM(args, 0);
		else if (size == 0)
		    args = NULL;
	    }
	    if (PyCFunction_GET_FLAGS(func) & METH_KEYWORDS) {
		    register PyObject *v;
		    v = (*(PyCFunctionWithKeywords)\
			 PyCFunction_GET_FUNCTION(func))\
			  (PyCFunction_GET_SELF(func), 
			   args, kw);
		    if (v == NULL) {
			Py_DECREF(func);
			goto onError;
		    }
		    PyTuple_SET_ITEM(w,i,v);
		}
	    else {
		if (kw != NULL && PyDict_Size(kw) != 0) {
		    PyErr_SetString(PyExc_TypeError,
				  "this function takes no keyword arguments");
		    return NULL;
		} 
		else {
		    register PyObject *v;
		    v = (*PyCFunction_GET_FUNCTION(func))\
			(PyCFunction_GET_SELF(func), args);
		    if (v == NULL) {
			Py_DECREF(func);
			goto onError;
		    }
		    PyTuple_SET_ITEM(w,i,v);
		}
	    }
	}
	else
#endif
	    {
		register PyObject *v;
		v = PyEval_CallObjectWithKeywords(func,arg,kw);
		if (v == NULL) {
		    Py_DECREF(func);
		    goto onError;
		}
		PyTuple_SET_ITEM(w,i,v);
	    }
	Py_DECREF(func);
    }
    
    Py_XDECREF(arg);
    return w;

 onError:
    Py_XDECREF(w);
    Py_XDECREF(arg);
    return NULL;
}

Py_C_Function( mxTools_method_mapply,
	       "method_mapply(objects,methodname,args=(),kw={})\n\n"
	       "Calls the method methodname of all objects in the given\n"
	       "order with the same arguments and returns a tuple with\n"
	       "the return values.")
{
    register Py_ssize_t i;
    Py_ssize_t n;
    PyObject *objects;
    PyObject *arg = 0,*kw = 0;
    PyObject *w = 0;
    char *methodname;

    Py_Get4Args("Os|OO",
		objects,methodname,arg,kw);

    Py_XINCREF(arg);

    n = PySequence_Length(objects);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "first argument must be a sequence");

    w = PyTuple_New(n);
    if (w == NULL)
	goto onError;

    if (arg == NULL)
	arg = PyTuple_New(0);
    if (arg == NULL)
	goto onError;

    for (i = 0; i < n; i++) {
	register PyObject *func;
	{
	    register PyObject *v;
	    v = PySequence_GetItem(objects,i);
	    if (!v)
		goto onError;
	    func = PyObject_GetAttrString(v,methodname);
	    if (!func) {
		Py_DECREF(v);
		goto onError;
	    }
	    Py_DECREF(v);
	}
#ifdef PyCFunction_GET_FUNCTION
	/* Short-cut for C functions, taken from
	   ceval.c:call_builtin(); Note: this only works and is used
	   with my patched version of the interpreter. XXX Update when
	   ceval.c changes !!! */
	if (PyCFunction_Check(func)) {
	    PyObject *args = arg;
	    
	    if (!(PyCFunction_GET_FLAGS(func) & METH_VARARGS)) {
		Py_ssize_t size = PyTuple_GET_SIZE(args);
		if (size == 1)
		    args = PyTuple_GET_ITEM(args, 0);
		else if (size == 0)
		    args = NULL;
	    }
	    if (PyCFunction_GET_FLAGS(func) & METH_KEYWORDS) {
		    register PyObject *v;
		    v = (*(PyCFunctionWithKeywords)\
			 PyCFunction_GET_FUNCTION(func))\
			  (PyCFunction_GET_SELF(func), 
			   args, kw);
		    if (v == NULL) {
			Py_DECREF(func);
			goto onError;
		    }
		    PyTuple_SET_ITEM(w,i,v);
		}
	    else {
		if (kw != NULL && PyDict_Size(kw) != 0) {
		    PyErr_SetString(PyExc_TypeError,
				  "this function takes no keyword arguments");
		    return NULL;
		} 
		else {
		    register PyObject *v;
		    v = (*PyCFunction_GET_FUNCTION(func))\
			(PyCFunction_GET_SELF(func), args);
		    if (v == NULL) {
			Py_DECREF(func);
			goto onError;
		    }
		    PyTuple_SET_ITEM(w,i,v);
		}
	    }
	}
	else
#endif
	    {
		register PyObject *v;
		v = PyEval_CallObjectWithKeywords(func,arg,kw);
		if (v == NULL) {
		    Py_DECREF(func);
		    goto onError;
		}
		PyTuple_SET_ITEM(w,i,v);
	    }
	Py_DECREF(func);
    }
    
    Py_XDECREF(arg);
    return w;

 onError:
    Py_XDECREF(w);
    Py_XDECREF(arg);
    return NULL;
}

Py_C_Function( mxTools_trange,
	       "trange([start=0,]stop[,step=1])\n\n"
	       "Returns tuple(range(start,stop,step))")
{
    Py_ssize_t start, stop=INT_MAX, step=INT_MAX;
    Py_ssize_t n;
    register Py_ssize_t i;
    register Py_ssize_t index;
    PyObject *t = 0;

    Py_Get3Args(Py_SSIZE_T_PARSERMARKER
		"|"
		Py_SSIZE_T_PARSERMARKER
		Py_SSIZE_T_PARSERMARKER,
		start,stop,step);

    /* Get the boundaries right... */
    if (stop == INT_MAX) {
	stop = start;
	if (stop < 0)
	    stop = 0;
	start = 0;
	step = 1;
	n = stop;
    }
    else if (step == INT_MAX) {
	if (start > stop)
	    start = stop;
	step = 1;
	n = stop - start;
    }
    else {
	Py_Assert(step != 0,
		  PyExc_ValueError,
		  "step must not be zero");
	if (step > 0) {
	    if (start > stop)
		start = stop;
	    n = (stop - start + step - 1) / step;
	}
	else {
	    if (start < stop)
		start = stop;
	    n = (start - stop - step - 1) / (-step);
	}
    }
	
    t = PyTuple_New(n);
    if (!t)
	goto onError;
    
    if (step == 1)
	for (index = 0, i = start; index < n; index++, i++) {
	    register PyObject *v = PyInt_FromLong((long)i);
	    if (!v)
		goto onError;
	    PyTuple_SET_ITEM(t,index,v);
	}
    else
	for (index = 0, i = start; index < n; index++, i += step) {
	    register PyObject *v = PyInt_FromLong((long)i);
	    if (!v)
		goto onError;
	    PyTuple_SET_ITEM(t,index,v);
	}
	
    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_indices,
	       "indices(object)\n\n"
	       "Returns tuple(range(len(object))).")
{
    register Py_ssize_t n;
    register Py_ssize_t index;
    register PyObject *t = 0;
    PyObject *w;

    Py_GetArgObject(w);

    n = PyObject_Length(w);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "argument must have a __len__ method");

    t = PyTuple_New(n);
    if (!t)
	goto onError;
    
    for (index = 0; index < n; index++) {
	register PyObject *v = PyInt_FromLong((long)index);
	if (!v)
	    goto onError;
	PyTuple_SET_ITEM(t,index,v);
    }
	
    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_range_len,
	       "range_len(object)\n"
	       "Returns range(len(object)).")
{
    register Py_ssize_t n;
    register Py_ssize_t index;
    register PyObject *t = 0;
    PyObject *w;

    Py_GetArgObject(w);

    n = PyObject_Length(w);
    if (n < 0)
	goto onError;

    t = PyList_New(n);
    if (!t)
	goto onError;
    
    for (index = 0; index < n; index++) {
	register PyObject *v = PyInt_FromLong((long)index);
	if (!v)
	    goto onError;
	PyList_SET_ITEM(t,index,v);
    }
	
    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_irange,
	       "irange(object[,indices])\n\n"
	       "Returns a tuple of tuples (index,object[index]), one\n"
	       "for each item in the sequence indices or, if this is not\n"
	       "given, in trange(len(object)).")
{
    register Py_ssize_t n;
    register Py_ssize_t index;
    PyObject *t = 0;
    PyObject *w;
    PyObject *indices = 0;

    Py_Get2Args("O|O",
		w,indices);

    if (!indices) {
	n = PyObject_Length(w);
	if (n < 0)
	    Py_Error(PyExc_TypeError,
		     "first argument must have a __len__ method");
    }
    else {
	n = PyObject_Length(indices);
	if (n < 0)
	    Py_Error(PyExc_TypeError,
		     "second argument must be a sequence");
    }

    t = PyTuple_New(n);
    if (!t)
	goto onError;
    
    if (!indices)
	for (index = 0; index < n; index++) {
	    register PyObject *u;
	    PyObject *v;
	    PyObject *x;
	    v = PyInt_FromLong((long)index);
	    if (!v)
		goto onError;
	    u = PyTuple_New(2);
	    if (!u) {
		Py_DECREF(v);
		goto onError;
	    }
	    x = PyObject_GetItem(w,v);
	    if (!x) {
		Py_DECREF(v);
		Py_DECREF(u);
		goto onError;
	    }
	    PyTuple_SET_ITEM(u,0,v);
	    PyTuple_SET_ITEM(u,1,x);
	    PyTuple_SET_ITEM(t,index,u);
	}
    else
	for (index = 0; index < n; index++) {
	    register PyObject *u;
	    PyObject *x;
	    PyObject *v;
	    v = PySequence_GetItem(indices,index);
	    if (!v)
		goto onError;
	    u = PyTuple_New(2);
	    if (!u) {
		Py_DECREF(v);
		goto onError;
	    }
	    x = PyObject_GetItem(w,v);
	    if (!x) {
		Py_DECREF(v);
		Py_DECREF(u);
		goto onError;
	    }
	    PyTuple_SET_ITEM(u,0,v);
	    PyTuple_SET_ITEM(u,1,x);
	    PyTuple_SET_ITEM(t,index,u);
	}

    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_get,
	       "get(object,index[,default])\n\n"
	       "Returns object[index], or, if that fails, default.")
{
    PyObject *x, *w, *index;
    PyObject *def = mxNotGiven;

    Py_Get3Args("OO|O",
		w,index,def);

    x = PyObject_GetItem(w,index);
    if (!x) {
	if (def != mxNotGiven) {
	    PyErr_Clear();
	    x = def;
	    Py_INCREF(x);
	}
	else
	    goto onError;
    }
    return x;

 onError:
    return NULL;
}

Py_C_Function( mxTools_extract,
	       "extract(object,indices[,defaults])\n\n"
	       "Returns a list of entries object[index] for each index\n"
	       "in the sequence indices. defaults must have the same length\n"
	       "as indices and is used to provide default values in case\n"
	       "the lookup fails.")
{
    Py_ssize_t n = 0;
    register Py_ssize_t index;
    PyObject *t = 0;
    PyObject *w;
    PyObject *indices;
    PyObject *defaults = 0;

    Py_Get3Args("OO|O",
		w,indices,defaults);

    n = PyObject_Length(indices);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "second argument must be a sequence");
    
    t = PyList_New(n);
    if (!t)
	goto onError;
    
    if (defaults)
	for (index = 0; index < n; index++) {
	    register PyObject *x;
	    register PyObject *v;

	    v = PySequence_GetItem(indices,index);
	    if (!v) {
		PyErr_Format(PyExc_IndexError,
			     "index value nr. %ld not accessible",
			     (long)index);
		goto onError;
	    }
	    x = PyObject_GetItem(w,v);
	    Py_DECREF(v);
	    if (!x) {
		/* Use default value */
		PyErr_Clear();
		x = PySequence_GetItem(defaults,index);
		if (!x) {
		    PyErr_Format(
			     PyExc_IndexError,
			     "default value for index nr. %ld not accessible",
			     (long)index);
		    goto onError;
		}
	    }
	    PyList_SET_ITEM(t,index,x);
	}
    else
	for (index = 0; index < n; index++) {
	    register PyObject *x;
	    register PyObject *v;

	    v = PySequence_GetItem(indices,index);
	    if (!v) {
		PyErr_Format(PyExc_IndexError,
			     "index value nr. %ld not accessible",
			     (long)index);
		goto onError;
	    }
	    x = PyObject_GetItem(w,v);
	    Py_DECREF(v);
	    if (!x) {
		PyErr_Format(PyExc_IndexError,
			     "default value for index nr. %ld not accessible",
			     (long)index);
		goto onError;
	    }
	    PyList_SET_ITEM(t,index,x);
	}

    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_iremove,
	       "iremove(object,indices)\n\n"
	       "Removes the items indexed by indices from object.\n"
	       "For sequences the index list must be sorted ascending;\n"
	       "an IndexError will be raised otherwise (object is then\n"
	       "left in an undefined state)."
	       )
{
    Py_ssize_t n = 0;
    register Py_ssize_t index;
    PyObject *w;
    PyObject *indices;

    Py_Get2Args("OO",
		w,indices);

    n = PyObject_Length(indices);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "second argument must be a sequence");
    
    if (PyMapping_Check(w))
	for (index = n - 1; index >= 0; index--) {
	    register PyObject *v;
	    register int rc;
	    
	    v = PySequence_GetItem(indices,index);
	    if (!v) {
		PyErr_Format(PyExc_IndexError,
			     "index %ld not accessible",
			     (long)index);
		goto onError;
	    }
	    rc = PyMapping_DelItem(w,v);
	    Py_DECREF(v);
	    if (rc)
        	goto onError;
	}

    else if (PySequence_Check(w)) {
	Py_ssize_t prev_index = INT_MAX;
	
	for (index = n - 1; index >= 0; index--) {
	    register PyObject *v;
	    register Py_ssize_t i;
	    
	    v = PySequence_GetItem(indices,index);
	    if (!v && PyInt_Check(v)) {
		PyErr_Format(PyExc_IndexError,
			     "index %ld not accessible or not an integer",
			     (long)index);
		goto onError;
	    }
	    i = PyInt_AS_LONG(v);
	    Py_DECREF(v);
	    if (prev_index >= i) {
		if (PySequence_DelItem(w,i))
		    goto onError;
		prev_index = i;
	    }
	    else
		Py_Error(PyExc_IndexError,
			 "indices must be sorted ascending for sequences");
	}
    }
    
    else
	Py_Error(PyExc_TypeError,
		 "object must be a mapping or a sequence");
    
    Py_ReturnNone();

 onError:
    return NULL;
}

Py_C_Function( mxTools_ifilter,
	       "ifilter(condition,object[,indices])\n\n"
	       "Returns a list of tuples (index,object[index]) such that\n"
	       "condition(object[item]) is true and index is found in\n"
	       "the sequence indices (defaulting to indices(object)).\n"
	       "Order is preserved. condition must be a callable object.")
{
    Py_ssize_t n;
    register Py_ssize_t index;
    PyObject *t = 0;
    PyObject *w;
    PyObject *indices = 0;
    PyObject *condition;
    PyObject *argtuple = 0;

    Py_Get3Args("OO|O",
		condition,w,indices);

    if (!indices) {
	n = PyObject_Length(w);
	if (n < 0)
	    Py_Error(PyExc_TypeError,
		     "second argument must be have a __len__ method");
    }
    else {
	n = PyObject_Length(indices);
	if (n < 0)
	    Py_Error(PyExc_TypeError,
		     "third argument must be a sequence");
    }

    t = PyList_New(0);
    if (!t)
	goto onError;
    
    argtuple = PyTuple_New(1);
    if (!argtuple)
	goto onError;

    if (!indices)
	for (index = 0; index < n; index++) {
	    register PyObject *v;
	    register PyObject *x;
	    register PyObject *z;

	    v = PyInt_FromLong((long)index);
	    if (!v)
		goto onError;
	    x = PyObject_GetItem(w,v);
	    if (!x) {
		Py_DECREF(v);
		goto onError;
	    }
	    /* Replace the argtuple entry with the new item x */
	    Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
	    PyTuple_SET_ITEM(argtuple,0,x);
	    /* Add a tuple if condition says it's ok */
	    z = PyEval_CallObject(condition,argtuple);
	    if (!z)
		goto onError;
	    if (PyObject_IsTrue(z)) {
		register PyObject *u;

		u = PyTuple_New(2);
		if (!u) {
		    Py_DECREF(v);
		    Py_DECREF(z);
		    goto onError;
		}
		Py_INCREF(x);
		PyTuple_SET_ITEM(u,0,v);
		PyTuple_SET_ITEM(u,1,x);
		PyList_Append(t,u);
		Py_DECREF(u);
	    }
	    else
		Py_DECREF(v);
	    Py_DECREF(z);
	}
    else
	for (index = 0; index < n; index++) {
	    register PyObject *v;
	    register PyObject *x;
	    register PyObject *z;

	    v = PySequence_GetItem(indices,index);
	    if (!v)
		goto onError;
	    x = PyObject_GetItem(w,v);
	    if (!x) {
		Py_DECREF(v);
		goto onError;
	    }
	    /* Replace the argtuple entry with the new item x */
	    Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
	    PyTuple_SET_ITEM(argtuple,0,x);
	    /* Add a tuple if condition says it's ok */
	    z = PyEval_CallObject(condition,argtuple);
	    if (!z)
		goto onError;
	    if (PyObject_IsTrue(z)) {
		register PyObject *u;

		u = PyTuple_New(2);
		if (!u) {
		    Py_DECREF(v);
		    Py_DECREF(z);
		    goto onError;
		}
		Py_INCREF(x);
		PyTuple_SET_ITEM(u,0,v);
		PyTuple_SET_ITEM(u,1,x);
		PyList_Append(t,u);
		Py_DECREF(u);
	    }
	    else
		Py_DECREF(v);
	    Py_DECREF(z);
	}

    Py_DECREF(argtuple);
    return t;

 onError:
    Py_XDECREF(argtuple);
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_tuples,
	       "tuples(sequence)\n\n"
	       "Returns a list much like apply(map,(None,)+tuple(sequence)))\n"
	       "does. Only with a bit more intuitive name. This function does\n"
	       "not optimize for the case where the sequences are of different\n"
	       "size and the resulting list of tuples will always\n"
	       "have the length of the first sequence. Missing entries\n"
	       "from the other sequences are filled in with None."
	       )
{
    Py_ssize_t n,m;
    register Py_ssize_t i;
    register Py_ssize_t j;
    PyObject *l = 0;
    PyObject *arg,*w;

    Py_GetArgObject(arg);

    /* Get tuple size (m) */
    m = PySequence_Length(arg);
    Py_Assert(m > 0,
              PyExc_TypeError,
              "sequence must have at least one element");

    /* Get list size (n) */
    w = PySequence_GetItem(arg,0);
    if (!w)
	goto onError;
    n = PySequence_Length(w);
    Py_DECREF(w);
    Py_Assert(n >= 0,
	      PyExc_TypeError,
	      "sequence elements must be sequences");

    /* XXX Could speed this up by rearranging and joining the loops */

    /* Create list of tuples */
    l = PyList_New(n);
    if (!l)
	goto onError;
    for (j = 0; j < n; j++) {
        PyObject *v;
        
        v = PyTuple_New(m);
	if (!v)
	    goto onError;
	PyList_SET_ITEM(l,j,v);
    }

    /* Fill them in */
    for (i = 0; i < m; i++) {
	PyObject *u;
	
	u = PySequence_GetItem(arg,i);
	if (!u)
	    goto onError;
	
	for (j = 0; j < n; j++) {
	    PyObject *v;
	    
	    v = PySequence_GetItem(u,j);
	    if (!v) {
		if (PyErr_ExceptionMatches(PyExc_IndexError)) {
		    PyErr_Clear();
		    /* Fill up the rest with None */
		    for (; j < n; j++) {
			Py_INCREF(Py_None);
			PyTuple_SET_ITEM(PyList_GET_ITEM(l,j),i,Py_None);
		    }
		    break;
		}
		else {
		    Py_DECREF(u);
		    goto onError;
		}
	    }
	    PyTuple_SET_ITEM(PyList_GET_ITEM(l,j),i,v);
	}
	Py_DECREF(u);
    }
    return l;

 onError:
    Py_XDECREF(l);
    return NULL;
}

Py_C_Function( mxTools_lists,
	       "lists(sequence)\n\n"
	       "Same as tuples(), except that a tuple of lists is created."
	       )
{
    Py_ssize_t n,m;
    register Py_ssize_t i;
    register Py_ssize_t j;
    PyObject *t = 0;
    PyObject *arg,*w;

    Py_GetArgObject(arg);

    /* Get list size (n) */
    n = PySequence_Length(arg);
    Py_Assert(n > 0,
              PyExc_TypeError,
              "sequence must have at least one element");

    /* Get tuple size (m) */
    w = PySequence_GetItem(arg,0);
    if (!w)
	goto onError;
    m = PySequence_Length(w);
    Py_DECREF(w);
    Py_Assert(m >= 0,
	      PyExc_TypeError,
	      "sequence elements must be sequences");

    /* XXX Could speed this up by rearranging and joining the loops */
    
    /* Create tuple of lists */
    t = PyTuple_New(m);
    if (!t)
        goto onError;
    for (j = 0; j < m; j++) {
        PyObject *v;
        
        v = PyList_New(n);
        if (!v)
            goto onError;
        PyTuple_SET_ITEM(t,j,v);
    }

    /* Fill them in */
    for (i = 0; i < n; i++) {
	PyObject *u;
            
	u = PySequence_GetItem(arg,i);
	if (!u)
	    goto onError;

	for (j = 0; j < m; j++) {
	    PyObject *v;
                
	    v = PySequence_GetItem(u,j);
	    if (!v) {
		if (PyErr_ExceptionMatches(PyExc_IndexError)) {
		    PyErr_Clear();
		    /* Fill up the rest with None */
		    for (; j < n; j++) {
			Py_INCREF(Py_None);
			PyList_SET_ITEM(PyTuple_GET_ITEM(t,j),i,Py_None);
		    }
		    break;
		}
		else {
		    Py_DECREF(u);
		    goto onError;
		}
	    }
	    PyList_SET_ITEM(PyTuple_GET_ITEM(t,j),i,v);
	}
	Py_DECREF(u);
    }
    return t;

 onError:
    Py_XDECREF(t);
    return NULL;
}

Py_C_Function( mxTools_count,
	       "count(condition,sequence)\n\n"
	       "Count the number of objects in sequence for which the\n"
	       "selection function condition returns true and return the\n"
	       "result as integer.")
{
    PyObject *condition;
    PyObject *list;
    PyObject *argtuple = 0;
    register Py_ssize_t i;
    register Py_ssize_t n;
    Py_ssize_t length;

    Py_Get2Args("OO",
		condition,list);

    length = PySequence_Length(list);
    if (length < 0)
	Py_Error(PyExc_TypeError,
		 "second argument must be a sequence");

    argtuple = PyTuple_New(1);
    if (!argtuple)
	goto onError;

    for(i = 0, n = 0; i < length; i++) {
	register PyObject *v;
	register PyObject *w;

	v = PySequence_GetItem(list,i);
	if (!v)
	    goto onError;

	/* Replace the argtuple entry with the new item */
	Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
	PyTuple_SET_ITEM(argtuple,0,v);

	/* Let's see what condition thinks about this item */
	w = PyEval_CallObject(condition,argtuple);
	if (!w)
	    goto onError;
	if (PyObject_IsTrue(w))
	    n++;
	Py_DECREF(w);
    }

    Py_DECREF(argtuple);
    return PyInt_FromLong((long)n);
onError:
    Py_XDECREF(argtuple);
    return NULL;
}

Py_C_Function( mxTools_exists,
	       "exists(condition,sequence)\n"
	       "Return 1 if and only if condition is true for at least one\n"
	       "of the items in sequence and 0 otherwise. condition\n"
	       "must be a callable object.")
{
    PyObject *condition;
    PyObject *list;
    PyObject *argtuple = 0;
    register Py_ssize_t i;
    Py_ssize_t n;
    Py_ssize_t length;

    Py_Get2Args("OO",
		condition,list);

    length = PySequence_Length(list);
    if (length < 0)
	Py_Error(PyExc_TypeError,
		 "second argument must be a sequence");

    argtuple = PyTuple_New(1);
    if (!argtuple)
	goto onError;

    for(i = 0, n = 0; i < length; i++) {
	register PyObject *v;
	register PyObject *w;

	v = PySequence_GetItem(list,i);
	if (!v)
	    goto onError;

	/* Replace the argtuple entry with the new item */
	Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
	PyTuple_SET_ITEM(argtuple,0,v);

	/* Let's see what condition thinks about this item */
	w = PyEval_CallObject(condition,argtuple);
	if (!w)
	    goto onError;
	if (PyObject_IsTrue(w)) {
	    n = 1;
	    Py_DECREF(w);
	    break;
	}
	Py_DECREF(w);
    }

    Py_DECREF(argtuple);
    return PyInt_FromLong((long)n);
 onError:
    Py_XDECREF(argtuple);
    return NULL;
}

Py_C_Function( mxTools_forall,
	       "forall(condition,sequence)\n\n"
	       "Return 1 if and only if condition is true for all\n"
	       "of the items in sequence and 0 otherwise. condition\n"
	       "must be a callable object.")
{
    PyObject *condition;
    PyObject *list;
    PyObject *argtuple = 0;
    register Py_ssize_t i;
    Py_ssize_t n;
    Py_ssize_t length;

    Py_Get2Args("OO",
		condition,list);

    length = PySequence_Length(list);
    if (length < 0)
	Py_Error(PyExc_TypeError,
		 "second argument must be a sequence");

    argtuple = PyTuple_New(1);
    if (!argtuple)
	goto onError;

    for(i = 0, n = 1; i < length; i++) {
	register PyObject *v;
	register PyObject *w;

	v = PySequence_GetItem(list,i);
	if (!v)
	    goto onError;

	/* Replace the argtuple entry with the new item */
	Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
	PyTuple_SET_ITEM(argtuple,0,v);

	/* Let's see what condition thinks about this item */
	w = PyEval_CallObject(condition,argtuple);
	if (!w)
	    goto onError;
	if (!PyObject_IsTrue(w)) {
	    n = 0;
	    Py_DECREF(w);
	    break;
	}
	Py_DECREF(w);
    }

    Py_DECREF(argtuple);
    return PyInt_FromLong((long)n);
 onError:
    Py_XDECREF(argtuple);
    return NULL;
}

Py_C_Function( mxTools_index,
               "index(condition,sequence)\n\n"
               "Return the index of the first item for which condition\n"
	       "returns true. A ValueError is raised in case no item\n"
	       "is found.")
{
    PyObject *condition;
    PyObject *list = 0;
    PyObject *argtuple = 0;
    register Py_ssize_t i;
    Py_ssize_t n;
    Py_ssize_t length;

    Py_Get2Args("OO",
		condition,list);

    length = PySequence_Length(list);
    if (length < 0)
        goto onError;

    argtuple = PyTuple_New(1);
    if (!argtuple)
        goto onError;

    for(i = 0, n = -1; i < length; i++) {
        register PyObject *v;
        register PyObject *w;

        v = PySequence_GetItem(list,i);
        if (!v)
            goto onError;

        /* Replace the argtuple entry with the new item */
        Py_XDECREF(PyTuple_GET_ITEM(argtuple,0));
        PyTuple_SET_ITEM(argtuple,0,v);

        /* Let's see what condition thinks about this item */
        w = PyEval_CallObject(condition,argtuple);
        if (!w)
            goto onError;
        if (PyObject_IsTrue(w)) {
            n = i;
            Py_DECREF(w);
            break;
        }
        Py_DECREF(w);
    }
    if (n == -1)
	Py_Error(PyExc_ValueError,
		 "condition is false for all items in sequence");

    Py_DECREF(argtuple);
    return PyInt_FromLong((long)n);

 onError:
    Py_XDECREF(argtuple);
    return NULL;
}

Py_C_Function( mxTools_sizeof,
	       "sizeof(object)\n\n"
	       "Returns the size in memory of the object in bytes.\n"
	       "Note that this doesn't show any extra space allocated by\n"
	       "the object.")
{
    Py_ssize_t size;
    register PyObject *w;
    PyTypeObject *t;

    Py_GetArgObject(w);
    t = w->ob_type;
    size = t->tp_basicsize;
    if (t->tp_itemsize)
	size += t->tp_itemsize * ((PyVarObject *)w)->ob_size;
	
    return PyInt_FromLong((long)size);
 onError:
    return NULL;
}

Py_C_Function( mxTools_findattr,
	       "findattr(objectlist,attrname)\n\n"
	       "Returns the first attribute with name attrname found\n"
	       "among the objects in the list.")
{
    PyObject *list;
    PyObject *name;
    register Py_ssize_t i;
    Py_ssize_t length;

    Py_Get2Args("OO",
		list,name);

    length = PySequence_Length(list);
    if (length < 0)
	Py_Error(PyExc_TypeError,
		 "first argument must be a sequence");

    Py_Assert(PyString_Check(name),
	      PyExc_TypeError,
	      "second argument must be a string");

    for(i = 0; i < length; i++) {
	PyObject *v;
	PyObject *w;

	v = PySequence_GetItem(list,i);
	if (!v)
	    goto onError;

	w = PyObject_GetAttr(v,name);
	if (w)
	    return w;
	else if (!PyErr_ExceptionMatches(PyExc_AttributeError))
	    goto onError;
	else
	    PyErr_Clear();
    }
    Py_Error(PyExc_AttributeError,
	     PyString_AS_STRING(name));
 onError:
    return NULL;
}

Py_C_Function( mxTools_attrlist,
	       "attrlist(objectlist,attrname)\n\n"
	       "Returns a list of all attributes with the given name\n"
	       "found among the objects in objectlist."
	       )
{
    PyObject *list,*l=0;
    PyObject *name;
    register Py_ssize_t i;
    Py_ssize_t length;

    Py_Get2Args("OO",
		list,name);

    length = PySequence_Length(list);
    if (length < 0)
	Py_Error(PyExc_TypeError,
		 "first argument must be a sequence");

    Py_Assert(PyString_Check(name),
	      PyExc_TypeError,
	      "second argument must be a string");

    l = PyList_New(0);
    if (!l)
	goto onError;

    for(i = 0; i < length; i++) {
	PyObject *v;
	PyObject *w;

	v = PySequence_GetItem(list,i);
	if (!v)
	    goto onError;

	w = PyObject_GetAttr(v,name);
	if (w) {
	    PyList_Append(l,w);
	    Py_DECREF(w);
	}
	else if (!PyErr_ExceptionMatches(PyExc_AttributeError))
	    goto onError;
	else
	    PyErr_Clear();
    }
    return l;

 onError:
    Py_XDECREF(l);
    return NULL;
}

Py_C_Function( mxTools_dict,
	       "dict(seq)\n\n"
	       "Creates a dictionary from the given items sequence.\n"
	       "The sequence must contain sub-sequences of at least length 2,\n"
	       "the first entry being interpreted as the key and the second as\n"
	       "the value.")
{
    Py_ssize_t n;
    PyObject *seq,*d = 0;
    register Py_ssize_t i;
    register PyObject *k = 0;
    register PyObject *v = 0;

    Py_GetArgObject(seq);
    n = PySequence_Length(seq);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "argument must be a sequence");

    d = PyDict_New();
    if (!d)
	goto onError;

    for (i = 0; i < n; i++) {
	register PyObject *o;

	o = PySequence_GetItem(seq,i);
	if (!o)
	    goto onError;
	k = PySequence_GetItem(o,0);
	v = PySequence_GetItem(o,1);
	Py_DECREF(o);

	if (!k || !v) {
	    PyErr_Format(PyExc_TypeError,
			 "item %ld in sequence doesn't have two entries",
			 (long)i);
	    goto onError;
	}
	if (PyDict_SetItem(d,k,v))
	    goto onError;
	Py_DECREF(k);
	Py_DECREF(v);
    }

    return d;
 onError:
    Py_XDECREF(d);
    Py_XDECREF(k);
    Py_XDECREF(v);
    return NULL;
}

Py_C_Function( mxTools_setdict,
	       "setdict(seq,value=None)\n\n"
	       "Creates a dictionary from the given items sequence.\n"
	       "The sequence must hashable entries which are used as\n"
	       "dictionary keys. The values are all set to value."
	       )
{
    Py_ssize_t n;
    PyObject *seq,*d = 0,*value = 0;
    register Py_ssize_t i;

    Py_Get2Args("O|O",
		seq,value);
    n = PySequence_Length(seq);
    if (n < 0)
	Py_Error(PyExc_TypeError,
		 "argument must be a sequence");

    if (!value) {
	Py_INCREF(Py_None);
	value = Py_None;
    }
    else
	Py_INCREF(value);

    d = PyDict_New();
    if (!d)
	goto onError;

    for (i = 0; i < n; i++) {
	register PyObject *k;

	k = PySequence_GetItem(seq,i);
	if (!k)
	    goto onError;
	if (PyDict_SetItem(d,k,value))
	    goto onError;
	Py_DECREF(k);
    }

    Py_DECREF(value);
    return d;

 onError:
    Py_XDECREF(d);
    Py_XDECREF(value);
    return NULL;
}

Py_C_Function( mxTools_invdict,
	       "invdict(d)\n\n"
	       "Creates a dictionary with inverse mappings from the\n"
	       "given dictionary d.")
{
    Py_ssize_t pos;
    PyObject *key,*value;
    PyObject *d,*inv = 0;

    Py_GetArgObject(d);
    Py_Assert(PyDict_Check(d),
	      PyExc_TypeError,
	      "argument must be a dictionary");

    inv = PyDict_New();
    if (!inv)
	goto onError;

    pos = 0;
    while (PyDict_Next(d, &pos, &key, &value)) {
	if (PyDict_SetItem(inv,value,key))
	    goto onError;
    }

    return inv;
 onError:
    Py_XDECREF(inv);
    return NULL;
}

Py_C_Function( mxTools_reverse,
	       "reverse(seq)\n\n"
	       "Creates a new sequence with reversed order of the items in\n"
	       "seq. If seq is a tuple, then a tuple is returned. Otherwise\n"
	       "a list is returned.")
{
    PyObject *seq,*w = 0;

    Py_GetArgObject(seq);

    if (PyTuple_Check(seq)) {
	register Py_ssize_t i;
	register Py_ssize_t n = PyTuple_GET_SIZE(seq);
	
	w = PyTuple_New(n);
	if (!w)
	    goto onError;

	for(i = 0; i < n;) {
	    register PyObject *o;

	    o = PyTuple_GET_ITEM(seq,i);
	    Py_INCREF(o);
	    i++;
	    PyTuple_SET_ITEM(w,n-i,o);
	}
    }
    else if (PyList_Check(seq)) {
	register Py_ssize_t i;
	register Py_ssize_t n = PyList_GET_SIZE(seq);
	
	w = PyList_New(n);
	if (!w)
	    goto onError;

	for(i = 0; i < n;) {
	    register PyObject *o;

	    o = PyList_GET_ITEM(seq,i);
	    Py_INCREF(o);
	    i++;
	    PyList_SET_ITEM(w,n-i,o);
	}
    }
    else {
	register Py_ssize_t i;
	register Py_ssize_t n = PySequence_Length(seq);

	if (n < 0)
	    Py_Error(PyExc_TypeError,
		     "argument must be a sequence");

	w = PyList_New(n);
	if (!w)
	    goto onError;

	for(i = 0; i < n;) {
	    register PyObject *o;

	    o = PySequence_GetItem(seq,i);
	    if (!o)
		PyErr_Format(PyExc_IndexError,
			     "item %ld of sequence",
			     (long)i);
	    Py_INCREF(o);
	    i++;
	    PyList_SET_ITEM(w,n-i,o);
	}
    }

    return w;
 onError:
    Py_XDECREF(w);
    return NULL;
}

#ifdef INCLUDE_FUNSTUFF
static
void mxTools_free(void *p)
{
    free(p);
}

Py_C_Function( mxTools_malloc,
	       "malloc(x)\n\n")
{
    Py_ssize_t x;
    char *p;
    register Py_ssize_t i;
    register char *c;

    Py_GetSingleArg(Py_SSIZE_T_PARSERMARKER, x);

    /* Allocate virtual memory */
    p = (char *)malloc(x);
    if (!p) {
	PyErr_NoMemory();
	goto onError;
    }

    /* Turn the virtual memory into "real" one */
    i = x;
    c = p;
    while (i--)
	*c++ = '\0';

    return PyCObject_FromVoidPtr(p,mxTools_free);
 onError:
    return NULL;
}

Py_C_Function( mxTools_caching_eval,
	       "caching_eval(code_string)\n\n"
	       )
{
    PyObject *codestr;

    Py_GetArg("O", codestr);

    Py_Assert(PyString_Check(codestr),
	      PyExc_TypeError,
	      "arg must be a string");

    return mxTools_EvalCodeString(codestr);

 onError:
    return NULL;
}
#endif

Py_C_Function( mxTools_acquire,
	       "acquire(self,name[,baseobjattr='baseobj'])\n\n"
	       "Tries to get the attribute name from self.<baseobjattr>.\n"
	       "If this is not defined or None, an AttributeError is\n"
	       "raised. Otherwise getattr(self.<baseobjattr>,name) is\n"
	       "returned. Attribute names must not start with an\n"
	       "underscore (this too raises an AttributeError).\n")
{
    PyObject *obj,*baseobj,*name;
    PyObject *v,*baseobjattr = mxTools_BaseobjAttribute;

    static int recdepth;

    recdepth++;
    Py_Assert(recdepth < 2000,
	      PyExc_SystemError,
	      "maximum acquire() recursion depth exceeded");

    Py_Get3Args("OO|O",
		obj,name,baseobjattr);

    Py_Assert(PyString_Check(name),
	      PyExc_TypeError,
	      "attribute name must be a string");
    
    /* We don't acquire names starting with underscores */
    Py_Assert(PyString_AS_STRING(name)[0] != '_',
	      PyExc_AttributeError,
	      PyString_AS_STRING(name));

    /* baseobj = obj.<baseobjattr> */
    baseobj = PyObject_GetAttr(obj,baseobjattr);
    if (!baseobj || baseobj == Py_None) {
	Py_XDECREF(baseobj);
	Py_Error(PyExc_AttributeError,
		 PyString_AS_STRING(name));
    }
    
    /* Now return getattr(baseobj,name) */
    v = PyObject_GetAttr(baseobj,name);
    Py_DECREF(baseobj);
    recdepth--;
    return v;

 onError:
    recdepth--;
    return NULL;
}

Py_C_Function( mxTools_verbosity,
	       "verbosity([level])\n\n"
	       "Sets the value of the interpreter's verbosity flag.\n"
	       "Returns the flag's value before changing it or, when called\n"
	       "without level, the current value."
	       )
{
    int value = Py_VerboseFlag,
	old_value = value;

    Py_GetArg("|i", value);
    Py_VerboseFlag = value;

    return PyInt_FromLong((long)old_value);

 onError:
    return NULL;
}

Py_C_Function( mxTools_debugging,
	       "debugging([level])\n\n"
	       "Sets the value of the interpreter's debugging flag.\n"
	       "Returns the flag's value before changing it or, when called\n"
	       "without level, the current value."
	       )
{
    int value = Py_DebugFlag,
	old_value = value;

    Py_GetArg("|i", value);
    Py_DebugFlag = value;

    return PyInt_FromLong((long)old_value);

 onError:
    return NULL;
}

Py_C_Function( mxTools_optimization,
	       "optimization([level])\n\n"
	       "Sets the value of the interpreter's optimization flag.\n"
	       "Returns the flag's value before changing it or, when called\n"
	       "without level, the current value."
	       )
{
    int value = Py_OptimizeFlag,
	old_value = value;

    Py_GetArg("|i", value);
    Py_OptimizeFlag = value;

    return PyInt_FromLong((long)old_value);

 onError:
    return NULL;
}

Py_C_Function( mxTools_interactive,
	       "interactive([level])\n\n"
	       "Sets the value of the interpreter's interactive flag.\n"
	       "Returns the flag's value before changing it or, when called\n"
	       "without level, the current value."
	       )
{
    int value = Py_InteractiveFlag,
	old_value = value;

    Py_GetArg("|i", value);
    Py_InteractiveFlag = value;

    return PyInt_FromLong((long)old_value);

 onError:
    return NULL;
}

Py_C_Function( mxTools_cur_frame,
	       "cur_frame([offset=0])\n\n"
	       "Returns the current execution frame, optionally going up the\n"
	       "stack by offset levels. If there are less than offset\n"
	       "frames on the stack, None is returned. The function is thread\n"
	       "safe."
	       )
{
    PyFrameObject *frame = NULL;
    PyObject *v;
    Py_ssize_t offset = 0;

    Py_GetArg("|"Py_SSIZE_T_PARSERMARKER, offset);

    /* Get requested frame object */
    frame = (PyFrameObject *)PyEval_GetFrame();
    for (;offset > 0;offset--) {
	if (frame == NULL)
	    break;
	frame = frame->f_back;
    }

    /* Return frame or None */
    v = (PyObject *)frame;
    if (v == NULL)
	v = Py_None;
    Py_INCREF(v);
    return v;

 onError:
    return NULL;
}

#if 0

/* XXX replace with a generic protocol query API, e.g. 

   hasmethods(obj,('__getitem__','__len__'))

   which works for both instances *and* types !

*/

Py_C_Function( mxTools_issequence,
	       "issequence(obj)\n\n"
	       "Returns 1 iff obj exposes the sequence slot protocol,\n"
	       "and at least defines the __getitem__ method, 0 otherwise."
	       )
{
    int rc;
    PyObject *v;

    Py_GetArg("O", v);
    if (PyInstance_Check(v)) {
	PyObject *w;
	
	w = PyObject_GetAttrString("__getitem__");
	if (!w) {
	    PyErr_Clear();
	    rc = 0;
	}
	else {
	    Py_DECREF(w);
	    rc = 1;
	}
    }
    else {
	rc = (v->ob_type->tp_as_sequence &&
	      v->ob_type->tp_as_sequence->sq_item);
    }
    return rc;

 onError:
    return NULL;
}
#endif

Py_C_Function( mxTools_truth,
	       "truth(object)\n\n"
	       "Return the truth value of object as True or False singleton."
	       "Note that the two singletons are actually the integers 1 and 0."
	       )
{
    PyObject *obj;
    int istrue;
    
    Py_GetArg("O", obj);

    istrue = PyObject_IsTrue(obj);
    if (istrue < 0)
	goto onError;
    if (istrue)
	obj = Py_True;
    else
	obj = Py_False;
    Py_INCREF(obj);
    return obj;

 onError:
    return NULL;
}

Py_C_Function( mxTools_sign,
	       "sign(number)\n\n"
	       "Returns the signum of the number, i.e. -1 for negative\n"
	       "numbers, +1 for positive ones and 0 in case it is equal to 0"
	       )
{
    PyObject *obj,*neg = 0;
    int sign;
    
    Py_GetArg("O", obj);

    neg = PyNumber_Negative(obj);
    if (!neg) 
	goto onError;
    sign = PyObject_Compare(obj,neg);
    if (PyErr_Occurred())
	goto onError;
    Py_DECREF(neg);
    return PyInt_FromLong(sign);

 onError:
    Py_XDECREF(neg);
    return NULL;
}

Py_C_Function( mxTools_makeref,
	       "makeref(id)\n\n"
	       "Provided that id is a valid address of a Python object,\n"
	       "this function returns a new reference to it. You can use this\n"
	       "function to reaccess objects lost during garbage collection.\n"
	       "USE WITH CARE - since this can cause core dumps !"
	       )
{
    long id;
    PyObject *obj;
    
    Py_GetArg("l", id);

    /* Accessing the memory location at id can cause a core dump ! */
    obj = (PyObject *)id;

    /* Do some checks to prevent complete disasters... */
    Py_Assert(obj->ob_refcnt > 0,
	      PyExc_ValueError,
	      "object has zero or negative reference count");
    Py_Assert(obj->ob_type != NULL,
	      PyExc_ValueError,
	      "object has no associated type object");
    Py_Assert(obj->ob_type != NULL,
	      PyExc_ValueError,
	      "object has no associated type object");
    
    Py_INCREF(obj);
    return obj;

 onError:
    return NULL;
}

Py_C_Function( mxTools_dictscan,
	       "dictscan(dictobj[,prevposition=0])\n\n"
	       "Dictionary scanner. Returns a tuple (key,value,position)\n"
	       "containing the key,value pair and slot position of the next\n"
	       "item found in the dictionaries hash table after slot\n"
	       "prevposition. Raises an IndexError when the end\n"
	       "of the table is reached or the prevposition index is out of\n"
	       "range."
	       )
{
    Py_ssize_t pos = 0;
    PyObject *d,*key,*value;
    
    Py_Get2Args("O|"Py_SSIZE_T_PARSERMARKER,
		d, pos);

    Py_Assert(PyDict_Check(d),
	      PyExc_TypeError,
	      "object must be a dictionary");
    
    if (!PyDict_Next(d,&pos,&key,&value))
	Py_Error(PyExc_IndexError,
		 "end of scan or illegal index");
    Py_Return3Args("OO"Py_SSIZE_T_PARSERMARKER,
		   key,value,pos);

 onError:
    return NULL;
}

#ifdef HAVE_PY_GETARGCARGV

/* This API is available in all Python version since at least 2.1, but
   not made public via the Python.h header file. */
extern void Py_GetArgcArgv(int *argc, char ***argv);

Py_C_Function( mxTools_setproctitle,
	       "setproctitle(title)\n\n"
	       "Set the process title."
	       )
{
    char *title;
    Py_ssize_t titlelen;
    int argc;
    char **argv;
    int i, argv0_len;
    char *argv0;
    
    Py_Get2Args("s#", title, titlelen);

    Py_GetArgcArgv(&argc, &argv);

    /* Check how much space we can use to save the title. We have to
       be careful here, since the argv array items may not be all
       pointing to the same memory area. */
    argv0 = argv[0];
    argv0_len = strlen(argv0) + 1;
    for (i = 1; i < argc; i++) {
	if (argv[i] == argv0 + argv0_len)
	    argv0_len += strlen(argv[i]) + 1;
        else
	    break;
    }

    /* Don't count the last 0-termination byte */
    argv0_len -= 1;

    /* Copy the new title to the static buffer for the process title
       and 0-terminate it. */
    titlelen = min(titlelen, argv0_len);
    memcpy(argv0, title, titlelen);
    for (i = titlelen; i < argv0_len; i++)
	argv0[i] = '\0';

    /* Truncate the argv list and set all remaining entries to NULL */
    for (i = 1; i < argc; i++)
	argv[i] = 0;
    
    Py_ReturnNone();

 onError:
    return NULL;
}

#endif

#ifdef HAVE_DLOPEN

Py_C_Function( mxTools_dlopen,
	       "dlopen(libname, mode)\n\n"
	       "Load the shared lib libname using the flags given in mode.\n"
	       "mode defaults to Python's standard dlopenflags."
	       )
{
    char *libname;
    int mode = PyThreadState_GET()->interp->dlopenflags;
    void *handle = 0;
    
    Py_Get2Args("s|i", libname, mode);

    handle = dlopen(libname, mode);
    if (handle == NULL) {
	/* Get error information */
	const char *error = dlerror();
	if (error == NULL)
	    error = "unknown dlopen() error";
	Py_Error(PyExc_OSError, error);
    }
    return PyLong_FromVoidPtr(handle);

 onError:
    return NULL;
}

#endif

/* Helper for mxTools_verscmp */

static
int parselevel(char *s,
	       Py_ssize_t len,
	       Py_ssize_t start,
	       int *number,
	       char *rest)
{
    Py_ssize_t i;
    Py_ssize_t split = -1, number_len;
    char buffer[256];

    for (i = start; i < len; i++) {
	register char c = s[i];
	
	if (c == '.')
	    break;
	if (split < 0 && 
	    (c < '0' || c > '9'))
	    split = i;
    }
    if (split < 0) {
	rest[0] = '\0';
	split = i;
    }
    else {
	Py_ssize_t rest_len = i - split;
	memcpy(rest,&s[split],rest_len);
	rest[rest_len] = '\0';
    }
    number_len = split - start;
    if (0 < number_len && number_len < sizeof(buffer)) {
	memcpy(buffer,&s[start],number_len);
	buffer[number_len] = '\0';
	*number = atoi(buffer);
    }
    else
	*number = 0;
    return i + 1;
}

Py_C_Function( mxTools_verscmp,
	       "verscmp(a,b)\n\n"
	       "Compares two version strings and returns -1,0,1 for\n"
	       "<,==,> resp."
	       )
{
    char *a,*b;
    Py_ssize_t a_len,b_len;
    Py_ssize_t a_i,b_i;
    int a_n,b_n;
    char a_x[256],b_x[256];
    int cmp = 0;
    
    Py_Get4Args("s#s#",
		a, a_len, b, b_len);

    Py_Assert(a_len < 255 && b_len < 255,
	      PyExc_TypeError,
	      "version strings too long");

    DPRINTF("mxTools_verscmp: a: '%s' b: '%s'\n",a,b);

    for (a_i = b_i = 0;;) {
	a_i = parselevel(a, a_len, a_i, &a_n, a_x);
	b_i = parselevel(b, b_len, b_i, &b_n, b_x);
	DPRINTF("mxTools_verscmp: a: %i %i '%s'\n",a_i,a_n,a_x);
	DPRINTF("mxTools_verscmp: b: %i %i '%s'\n",b_i,b_n,b_x);

	if (a_n == b_n) {
	    int a_x_empty = (a_x[0] == '\0');
	    int b_x_empty = (b_x[0] == '\0');
	    if (a_x_empty && b_x_empty)
		/* 1.1 == 1.1 */
		;
	    else if (!a_x_empty && b_x_empty) {
		/* 1.1alpha < 1.1 */
		cmp = -1;
		break;
	    }
	    else if (a_x_empty && !b_x_empty) {
		/* 1.1 > 1.1alpha */
		cmp = +1;
		break;
	    }
	    else {
		cmp = strcmp(a_x,b_x);
		DPRINTF("mxTools_verscmp: strcmp(a_x,b_x) = %i\n",cmp);
		if (cmp != 0)
		    /* e.g. 1.1alpha1 < 1.1alpha2 */
		    break;
	    }
	}
	else {
	    cmp = (a_n < b_n) ? -1 : +1;
	    break;
	}
	if (a_i >= a_len && b_i >= b_len) {
	    cmp = 0;
	    break;
	}
    }

    return PyInt_FromLong(cmp);

 onError:
    return NULL;
}

/* --- Experimental safecall() API ---------------------------------- */

#define MXTOOLS_ENABLE_SAFECALL

#ifdef MXTOOLS_ENABLE_SAFECALL

#include <setjmp.h>
#include <signal.h>

/* safecall() environment

   This is *not* thread-safe, but then signals don't work reliably in
   the presence of threads anyway.

   XXX sigsetjmp et al. are not available on Windows and probably
       other platforms as well !

*/
static int safecall_environment_initialized = 0;
static sigjmp_buf safecall_environment;

/* safecall() signal handler */

static void safecall_handler(int signum) 
{
    DPRINTF("SIGSEGV handler called\n");

    /* Force SysV behavior: reset the signal handler to the default
       handler */
    signal(signum, SIG_DFL);

    if (safecall_environment_initialized)
	/* Jump back to the environment saved in the safecall function. */
	siglongjmp(safecall_environment, signum);
    else
	/* Reraise the signal (forcing the use of the default handler) */
	raise(signum);
}

/* Initialize the safecall_handler

   Note that a signal that invokes the handler will automatically
   cause the default handler to be installed again for the signal 

*/
static int init_safecall_handler(void) 
{
    DPRINTF("init SIGSEGV handler\n");
    signal(SIGSEGV, safecall_handler);
    signal(SIGBUS, safecall_handler);
    signal(SIGABRT, safecall_handler);
    signal(SIGILL, safecall_handler);
    signal(SIGFPE, safecall_handler);
    return 0;
}


/* Reset the signal handlers to their defaults */

static int reset_safecall_handler(void) 
{
    DPRINTF("reset SIGSEGV handler\n");
    signal(SIGSEGV, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    return 0;
}

Py_C_Function( mxTools_safecall,
	       "safecall(callable [,args, kws])\n\n"
	       "Calls the callable object callable using args and kws,\n"
               "if given. In the event of the call causing a segfault\n"
	       "or similar serious problem, the function will raise an\n"
	       "mx.Tools.ProgrammingError. The application can then terminate\n"
	       "gracefully. Note: This function is not thread-safe !"
	       )
{
    PyObject *callable, *callargs=NULL, *callkws=NULL;
    PyObject *result = NULL;
    PyObject *v;
    int signum;

    Py_Get3Args("O|OO", 
		callable, callargs, callkws);

    /* Save the current stack environment and call the callable */
    DPRINTF("setjmp()\n");
    signum = sigsetjmp(safecall_environment, 1);

    if (signum == 0) {
	/* Call the callable object and return gracefully if
	   possible */
	safecall_environment_initialized = 1;
	init_safecall_handler();
	result = PyEval_CallObjectWithKeywords(callable, callargs, callkws);
	safecall_environment_initialized = 0;
	reset_safecall_handler();
	return result;
    }

    /* We got here by a longjmp(); signum is the signal triggering
       this event. */
    DPRINTF("processing longjmp()\n");
    safecall_environment_initialized = 0;
    reset_safecall_handler();
    v = PyTuple_New(2);
    PyTuple_SET_ITEM(v, 0, PyString_FromString("Bug in external routine"));
    PyTuple_SET_ITEM(v, 1, PyInt_FromLong(signum));
    PyErr_SetObject(mxTools_ProgrammingError, v);

 onError:
    return NULL;
}

Py_C_Function( mxTools_segfault,
	       "segfault()\n\n"
	       "Cause a hard seg fault."
	       )
{
    char *p = NULL;
    char buffer[10];
    double a,b,c;
    int errtype = 0;
    
    Py_GetArg("|i", errtype);

    switch (errtype) {

    case 0:
	/* Cause a true seg fault by writing to a NULL pointer */
	memset(p, 0, 100);
	break;

    case 1:
	/* Double free() */
	p = malloc(100);
	free(p);
	free(p);
	break;

    case 2:
	/* Buffer overrun on stack */
	memset(buffer, 0, 20);
	break;
	
    case 3:
	/* Buffer underrun on stack */
	memset(buffer - 10, 0, 20);
	break;

    case 4:
	/* Division by 0 */
	a = 1;
	b = 0;
	c = a / b;
	break;
	
    default:
	Py_Error(PyExc_ValueError,
		 "segfault(): unknown error type");
	
    }
    Py_ReturnNone();

 onError:
    return NULL;
}

#endif

/* --- NotGiven Singleton -------------------------------------------------- */

static 
PyObject *mxNotGiven_Repr(PyObject *v)
{
    return PyString_FromString("NotGiven");
}

static 
int mxNotGiven_NonZero(PyObject *v)
{
    return 0;
}

typedef PyObject mxNotGivenObject;

static
PyNumberMethods mxNotGiven_TypeAsNumber = {

    /* These slots are not NULL-checked, so we must provide dummy functions */
    notimplemented2,				/*nb_add*/
    notimplemented2,				/*nb_subtract*/
    notimplemented2,				/*nb_multiply*/
    notimplemented2,				/*nb_divide*/
    notimplemented2,				/*nb_remainder*/
    notimplemented2,				/*nb_divmod*/
    notimplemented3,				/*nb_power*/
    notimplemented1,				/*nb_negative*/
    notimplemented1,				/*nb_positive*/

    /* Everything below this line EXCEPT nb_nonzero (!) is NULL checked */
    0,						/*nb_absolute*/
    mxNotGiven_NonZero,				/*nb_nonzero*/
    0,						/*nb_invert*/
    0,						/*nb_lshift*/
    0,						/*nb_rshift*/
    0,						/*nb_and*/
    0,						/*nb_xor*/
    0,						/*nb_or*/
    0,						/*nb_coerce*/
    0,						/*nb_int*/
    0,						/*nb_long*/
    0,						/*nb_float*/
    0,						/*nb_oct*/
    0,						/*nb_hex*/
};

static PyTypeObject mxNotGiven_Type = {
    PyObject_HEAD_INIT(0)			/* init at startup ! */
    0,						/*ob_size*/
    "NotGiven",					/*tp_name*/
    sizeof(mxNotGivenObject),			/*tp_basicsize*/
    0,						/*tp_itemsize*/
    0,						/*tp_dealloc; object always stays alive */
    0,						/*tp_print*/
    0,						/*tp_getattr*/
    0,						/*tp_setattr*/
    0,						/*tp_compare*/
    mxNotGiven_Repr, 				/*tp_repr*/
    &mxNotGiven_TypeAsNumber,			/*tp_as_number*/
    0,						/*tp_as_sequence*/
    0,						/*tp_as_mapping*/
    0,						/*tp_hash */
};

/* --- module init --------------------------------------------------------- */

/* Python Method Table */

static 
PyMethodDef Module_methods[] =
{   
    Py_MethodListEntry("trange", mxTools_trange),
    Py_MethodListEntrySingleArg("trange_len", mxTools_indices),
    Py_MethodListEntrySingleArg("indices", mxTools_indices),
    Py_MethodListEntrySingleArg("range_len", mxTools_range_len),
    Py_MethodListEntry("irange", mxTools_irange),
    Py_MethodListEntry("ifilter", mxTools_ifilter),
    Py_MethodListEntry("get", mxTools_get),
    Py_MethodListEntry("extract", mxTools_extract),
    Py_MethodListEntry("iremove", mxTools_iremove),
    Py_MethodListEntry("mget", mxTools_extract),
    Py_MethodListEntry("mgetattr", mxTools_findattr),
    Py_MethodListEntry("findattr", mxTools_findattr),
    Py_MethodListEntry("attrlist", mxTools_attrlist),
    Py_MethodListEntry("mapply", mxTools_mapply),
    Py_MethodListEntry("method_mapply", mxTools_method_mapply),
    Py_MethodListEntry("count", mxTools_count),
    Py_MethodListEntry("exists", mxTools_exists),
    Py_MethodListEntry("forall", mxTools_forall),
    Py_MethodListEntry("index", mxTools_index),
    Py_MethodListEntry("napply", mxTools_napply),
    Py_MethodListEntrySingleArg("sizeof", mxTools_sizeof),
    Py_MethodListEntrySingleArg("dict", mxTools_dict),
    Py_MethodListEntrySingleArg("invdict", mxTools_invdict),
    Py_MethodListEntry("setdict", mxTools_setdict),
    Py_MethodListEntrySingleArg("reverse", mxTools_reverse),
    Py_MethodListEntrySingleArg("tuples", mxTools_tuples),
    Py_MethodListEntrySingleArg("lists", mxTools_lists),
    Py_MethodListEntry("acquire", mxTools_acquire),
    Py_MethodListEntry("verbosity", mxTools_verbosity),
    Py_MethodListEntry("optimization", mxTools_optimization),
    Py_MethodListEntry("interactive", mxTools_interactive),
    Py_MethodListEntry("debugging", mxTools_debugging),
    Py_MethodListEntry("cur_frame", mxTools_cur_frame),
    Py_MethodListEntry("truth", mxTools_truth),
    Py_MethodListEntry("sign", mxTools_sign),
    Py_MethodListEntry("makeref", mxTools_makeref),
    Py_MethodListEntry("dictscan", mxTools_dictscan),
    Py_MethodListEntry("verscmp", mxTools_verscmp),
#ifdef HAVE_PY_GETARGCARGV
    Py_MethodListEntry("setproctitle", mxTools_setproctitle),
#endif
#ifdef HAVE_DLOPEN
    Py_MethodListEntry("dlopen",  mxTools_dlopen),
#endif
#ifdef INCLUDE_FUNSTUFF
    Py_MethodListEntrySingleArg("malloc", mxTools_malloc),
    Py_MethodListEntry("caching_eval", mxTools_caching_eval),
#endif
#ifdef MXTOOLS_ENABLE_SAFECALL
    Py_MethodListEntry("safecall", mxTools_safecall),
    Py_MethodListEntry("segfault", mxTools_segfault),
#endif
    {NULL,NULL} /* end of list */
};

/* Cleanup function */
static 
void mxToolsModule_Cleanup(void)
{
    Py_XDECREF(mxTools_BaseobjAttribute);
    mxTools_BaseobjAttribute = 0;

    /* Reset mxTools_Initialized flag */
    mxTools_Initialized = 0;
}

/* create PyMethodObjects and register them in the module's dict */
MX_EXPORT(void) 
     initmxTools(void)
{
    PyObject *module, *moddict;

    if (mxTools_Initialized)
	Py_Error(PyExc_SystemError,
		 "can't initialize "MXTOOLS_MODULE" more than once");

    /* Init type objects */
    PyType_Init(mxNotGiven_Type);

    /* create module */
    module = Py_InitModule4(MXTOOLS_MODULE, /* Module name */
			    Module_methods, /* Method list */
			    Module_docstring, /* Module doc-string */
			    (PyObject *)NULL, /* always pass this as *self */
			    PYTHON_API_VERSION); /* API Version */
    if (!module)
	goto onError;

    /* Register cleanup function */
    if (Py_AtExit(mxToolsModule_Cleanup))
	/* XXX what to do if we can't register that function ??? */;

    /* Create NotGiven singleton */
    mxNotGiven = PyObject_NEW(PyObject,&mxNotGiven_Type);
    if (!mxNotGiven)
	goto onError;

    /* Create acquire default argument for baseobjattr */
    mxTools_BaseobjAttribute = PyString_InternFromString("baseobj");
    if (!mxTools_BaseobjAttribute)
	goto onError;

    /* Add some constants to the module's dict */
    moddict = PyModule_GetDict(module);
    insstr(moddict, "__version__", MXTOOLS_VERSION);
    PyDict_SetItemString(moddict,
			 "NotGiven",
			 mxNotGiven);

    /* dlopen() mode flags */
#ifdef RTLD_LAZY
    insint(moddict, "RTLD_LAZY", RTLD_LAZY);
#endif
#ifdef RTLD_NOW
    insint(moddict, "RTLD_NOW", RTLD_NOW);
#endif
#ifdef RTLD_NOLOAD
    insint(moddict, "RTLD_NOLOAD", RTLD_NOLOAD);
#endif
#ifdef RTLD_DEEPBIND
    insint(moddict, "RTLD_DEEPBIND", RTLD_DEEPBIND);
#endif
#ifdef RTLD_GLOBAL
    insint(moddict, "RTLD_GLOBAL", RTLD_GLOBAL);
#endif
#ifdef RTLD_LOCAL
    insint(moddict, "RTLD_LOCAL", RTLD_LOCAL);
#endif
#ifdef RTLD_NODELETE
    insint(moddict, "RTLD_NODELETE", RTLD_NODELETE);
#endif

    /* Errors */
    if (!(mxTools_Error = insexc(moddict, "Error", NULL)))
	goto onError;
    if (!(mxTools_ProgrammingError = insexc(moddict, "ProgrammingError",
					    PyExc_RuntimeError)))
	goto onError;

    /* We are now initialized */
    mxTools_Initialized = 1;

 onError:
    /* Check for errors and report them */
    if (PyErr_Occurred())
	Py_ReportModuleInitError(MXTOOLS_MODULE);
    return;
}
