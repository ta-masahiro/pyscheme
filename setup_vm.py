from distutils.core import setup
from Cython.Build import cythonize

setup(ext_modules = cythonize('secd_vm.pyx'))
#setup(ext_modules = cythonize('matrix_cython.pyx'))
