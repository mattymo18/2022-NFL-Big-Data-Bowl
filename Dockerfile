FROM rocker/verse
MAINTAINER Matt Johnson <johnson.matt1818#gmail.com>

#Build Environment
RUN R -e "install.packages('Matrix')"
RUN R -e "install.packages('knitr')"
RUN R -e "install.packages('kableExtra')"
RUN R -e "install.packages('ggrepel')"
RUN R -e "install.packages('caret')"
RUN R -e "install.packages('glmnet')"
RUN R -e "install.packages('reactable')"
RUN R -e "install.packages('htmltools')"
RUN R -e "install.packages('reactablefmtr')"


