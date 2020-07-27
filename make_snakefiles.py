#!/usr/bin/env python3

from collections import namedtuple
from pathlib import Path
import sys
from jinja2 import Environment, FileSystemLoader
import pyexcel_ods3


TEMPLATE_DIR = Path("/trials/INSPIRED/code/snakemake/template")
OUTPUT_DIR = Path("/trials/INSPIRED/code/snakemake/snakefiles")
DEMOGRAPHICS_PATH = Path("/trials/INSPIRED/documents/demographics.ods")


Subject = namedtuple(
    "Subject",
    ("site", "type", "id", "dob", "age", "gender", "scan_date", "date_received")
)


def get_subjects():
    data = pyexcel_ods3.get_data(str(DEMOGRAPHICS_PATH))
    for r in data["Sheet1"][1:]:
        if not r:
            break
        if len(r) < 9:
            r.append(None)
        for i, v in enumerate(r):
            if not v:
                r[i] = "NA"
        yield Subject(*r[0:8])


def relpath_to(subject):
    site = int(subject.site)
    id_ = int(subject.id)
    return "{0:02d}/{1}/{2:03d}".format(site, subject.type, id_)


def main():
    jinja_env = Environment(
        loader=FileSystemLoader(str(TEMPLATE_DIR)),
        trim_blocks=True,
        auto_reload=True
    )
    for subject in get_subjects():
        relpath = relpath_to(subject)
        custom_template_path = TEMPLATE_DIR / relpath / "Snakefile.j2"
        out_dir = OUTPUT_DIR / relpath
        out_file = out_dir / 'Snakefile'
        if custom_template_path.exists():
            tplt = jinja_env.get_template(relpath + '/Snakefile.j2')
            print(subject, 'overrides default template', file=sys.stderr)
        else:
            tplt = jinja_env.get_template('default/Snakefile.j2')
        out_dir.mkdir(parents=True, exist_ok=True)
        with out_file.open("w") as f:
            f.write(tplt.render())


if __name__ == "__main__":
    main()
