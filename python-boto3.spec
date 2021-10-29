%global pkgname boto3
%define buildid @BUILDID@

Name:           python-%{pkgname}
Version:        1.17.14
Release:        CROC3%{?buildid}%{?dist}
Summary:        The AWS SDK for Python

License:        ASL 2.0
URL:            https://github.com/C2Devel/boto3.git
Source0:        https://pypi.io/packages/source/b/boto3/boto3-%{version}.tar.gz
BuildArch:      noarch

%description
Boto3 is the Amazon Web Services (AWS) Software Development
Kit (SDK) for Python, which allows Python developers to
write software that makes use of services like Amazon S3
and Amazon EC2.

%package -n     python%{python3_pkgversion}-%{pkgname}
Requires:       python%{python3_pkgversion}-botocore >= 1.20.14
Requires:       python%{python3_pkgversion}-jmespath >= 0.7.1
Requires:       python%{python3_pkgversion}-s3transfer >= 0.3.0

Summary:        The AWS SDK for Python
BuildRequires:  python%{python3_pkgversion}-devel
BuildRequires:  python%{python3_pkgversion}-setuptools
Provides:       python%{python3_pkgversion}-%{pkgname}

%description -n python%{python3_pkgversion}-%{pkgname}
Boto3 is the Amazon Web Services (AWS) Software Development
Kit (SDK) for Python, which allows Python developers to
write software that makes use of services like Amazon S3
and Amazon EC2.

%prep
%setup -q -n %{pkgname}-%{version}
rm -rf %{pkgname}.egg-info
# Remove online tests
rm -rf tests/integration

%build
%py3_build

%install
%py3_install

%files -n python%{python3_pkgversion}-%{pkgname}
%defattr(-,root,root,-)
%doc README.rst
%license LICENSE
%{python3_sitelib}/%{pkgname}
%{python3_sitelib}/%{pkgname}-%{version}-*.egg-info

%changelog
* Fri Sep 24 2021 Alex Rudenko <arudenko@croc.ru> - 1.17.14-CROC3
- spec: remove build for py2

* Fri Jul 02 2021 Andrey Kulaev <akulaev@croc.ru> - 1.17.14-CROC2
- Replace botocore dependency with croc version

* Wed Feb 24 2021 Alexander Chernev <achernev@croc.ru> - 1.17.14-CROC1
- Update to latest boto3 - 1.17.14
