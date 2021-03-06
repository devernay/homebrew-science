class Scalapack < Formula
  desc "high-performance linear algebra for distributed memory machines"
  homepage "http://www.netlib.org/scalapack/"
  url "http://www.netlib.org/scalapack/scalapack-2.0.2.tgz"
  sha256 "0c74aeae690fe5ee4db7926f49c5d0bb69ce09eea75beb915e00bba07530395c"
  revision 7

  head "https://icl.cs.utk.edu/svn/scalapack-dev/scalapack/trunk", :using => :svn

  bottle do
    cellar :any
    sha256 "742bce84d22fe05d80f2f357b0cce08527e34cab5cdff7b8a2b749e64ce2f316" => :sierra
    sha256 "4acfb5c2d1979bee44ec79371215cdc3173ace8100e87442b989198345a1436b" => :el_capitan
    sha256 "417487f2452d2e9ad500702b09522e88ba6f39b7ec8d1f8bf25b86c4186ba637" => :yosemite
    sha256 "a6c491eefc1456a555af7918469836110ee969920280fa41adaf10808b7db9b9" => :mavericks
  end

  option "without-test", "Skip build-time tests (not recommended)"
  deprecated_option "without-check" => "without-test"

  depends_on :mpi => [:cc, :f90]
  depends_on "cmake" => :build
  depends_on "openblas" => :optional
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?
  depends_on :fortran

  def install
    args = std_cmake_args
    args << "-DBUILD_SHARED_LIBS=ON"

    if build.with? "openblas"
      blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
      lapack = blas
    else
      blas = OS.mac? ? "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort" : "-lblas"
      lapack = OS.mac? ? blas : "-llapack"
    end
    args += ["-DBLAS_LIBRARIES=#{blas}", "-DLAPACK_LIBRARIES=#{lapack}"]

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "all"
      system "make", "install"
      system "make", "test" if build.with? "test"
    end

    pkgshare.install "EXAMPLE"
  end

  test do
    ENV.fortran
    cp_r pkgshare/"EXAMPLE", testpath
    cd "EXAMPLE" do
      system "mpif90", "-o", "xsscaex", "psscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert (`mpirun -np 4 ./xsscaex | grep 'INFO code' | awk '{print $NF}'`.to_i == 0)
      system "mpif90", "-o", "xdscaex", "pdscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert (`mpirun -np 4 ./xdscaex | grep 'INFO code' | awk '{print $NF}'`.to_i == 0)
      system "mpif90", "-o", "xcscaex", "pcscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert (`mpirun -np 4 ./xcscaex | grep 'INFO code' | awk '{print $NF}'`.to_i == 0)
      system "mpif90", "-o", "xzscaex", "pzscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert (`mpirun -np 4 ./xzscaex | grep 'INFO code' | awk '{print $NF}'`.to_i == 0)
    end
  end
end
