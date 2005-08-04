Summary: Radio interferometry data reduction package
Name: miriadC
Version: 4.0.4
Release: 1
Group: Applications/Astronomy
Copyright: See COPYRIGHT file for details
Packager:  teuben@astro.umd.edu
URL: http://www.astro.umd.edy/~teuben/miriad
Source: ftp://ftp.astro.umd.edu/progs/bima/miriad.tar.gz
Prefix: /usr/local/miriadC
ExclusiveOS: linux
BuildRoot: /tmp/build-root-%{name}
AutoReqProv: no

#%define __spec_install_post %{nil}
#%define __os_install_post %{nil}
%define __check_files %{nil}
#%define _unpackaged_files_terminate_build 1
#%define debug_package %{nil}
%description
Miriad is a radio interferometry data reduction package. Originally 
designed for reducing data from the Berkeley Illinois Maryland Array
(BIMA), the package is also used to process data from other 
arrays. Support for data reduction from ATCA, CARMA, SMA and WSRT 
have now been added. Don't confuse this pacakge with a separate ATCA
version of Miriad. Although they share a common root, and are mostly
compatible, their development has not been merged yet and is feared
to diverge.
MiriadA is the designation for the ATNF version. MiriadB the (now frozen)
version for BIMA, where MiriadC the one for CARMA,SMA,WSRT and ATNF.

%prep

%setup -q -c -n miriad
# unpack Miriad distribution

gtar -zxvf $RPM_SOURCE_DIR/miriad.tar.gz

%install

$RPM_BUILD_DIR/miriad/Install < $RPM_SOURCE_DIR/miriad.install

mkdir -p $RPM_BUILD_ROOT/usr/local/miriad
cp -pr $RPM_BUILD_DIR/miriad $RPM_BUILD_ROOT/usr/local/.
cp -pr $RPM_SOURCE_DIR/MIRRC.PATH $RPM_BUILD_ROOT/usr/local/miriad/bin/MIRRC
cd $RPM_BUILD_ROOT
find . -type d -fprint $RPM_BUILD_DIR/file.list.%{name}.dirs
find . -type f -fprint $RPM_BUILD_DIR/file.list.%{name}.files.tmp
sed '/\/man\//s/$/.gz/g' $RPM_BUILD_DIR/file.list.%{name}.files.tmp > 
$RPM_BUILD_DIR/file.list.%{name}.files
find . -type l -fprint $RPM_BUILD_DIR/file.list.%{name}.libs
sed '1,2d;s,^\.,\%attr(-\,root\,root) \%dir ,' 
$RPM_BUILD_DIR/file.list.%{name}.dirs > $RPM_BUILD_DIR/file.list.%{name}
sed 's,^\.,\%attr(-\,root\,root) ,' 
$RPM_BUILD_DIR/file.list.%{name}.files >> $RPM_BUILD_DIR/file.list.%{name}
sed 's,^\.,\%attr(-\,root\,root) ,' 
$RPM_BUILD_DIR/file.list.%{name}.libs >> $RPM_BUILD_DIR/file.list.%{name}

%clean

rm -rf $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_DIR/file.list.%{name}
rm -rf $RPM_BUILD_DIR/file.list.%{name}.libs
rm -rf $RPM_BUILD_DIR/file.list.%{name}.files
rm -rf $RPM_BUILD_DIR/file.list.%{name}.files.tmp
rm -rf $RPM_BUILD_DIR/file.list.%{name}.dirs

%files -f ../file.list.%{name}
%doc
%defattr(-,root,root,0775)


