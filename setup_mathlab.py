from distutils.core import setup
from Cython.Build import cythonize

setup(ext_modules = cythonize('mathlab.pyx'))
#setup(ext_modules = cythonize('matrix_cython.pyx'))
