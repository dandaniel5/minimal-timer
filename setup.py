#!/usr/bin/env python3
"""
Setup script for minimal-timer PyPI package
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

setup(
    name="minimal-timer",
    version="1.0.1",
    description="A minimalist command-line timer with smart time parsing and system integration",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Danil Kodolov",
    author_email="",
    url="https://github.com/dandaniel5/minimal-timer",
    license="GPL-3.0",
    
    # Package data
    py_modules=["timer"],
    
    # Requirements
    python_requires=">=3.6",
    install_requires=[],
    
    # Entry points
    entry_points={
        "console_scripts": [
            "timer=timer:main",
        ],
    },
    
    # Classifiers
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
        "Operating System :: OS Independent",
        "Operating System :: POSIX",
        "Operating System :: MacOS",
        "Operating System :: Microsoft :: Windows",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Utilities",
        "Topic :: Office/Business :: Scheduling",
    ],
    
    # Keywords
    keywords="timer countdown cli terminal pomodoro",
    
    # Project URLs
    project_urls={
        "Bug Reports": "https://github.com/dandaniel5/minimal-timer/issues",
        "Source": "https://github.com/dandaniel5/minimal-timer",
        "Documentation": "https://github.com/dandaniel5/minimal-timer#readme",
    },
)
