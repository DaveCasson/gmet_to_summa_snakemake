from setuptools import setup, find_packages

with open('requirements.txt') as f:
    required = f.read().splitlines()

setup(
    name='gmet_to_summa_snakemake',
    version='0.0.1',
    author='Dave Casson, Andy Wood',
    description='A Python project for converting GMET data to SUMMA inputs using Snakemake',
    packages=find_packages(),
    install_requires=[required
    ],
    entry_points={
        'console_scripts': [
            'gmet_to_summa_snakemake = gmet_to_summa_snakemake.main:main'
        ]
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
)
