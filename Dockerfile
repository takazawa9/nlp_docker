FROM nvcr.io/nvidia/pytorch:20.03-py3

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ENV HOME=/home/$NB_USER
#RUN git clone https://github.com/NVIDIA/apex.git && cd apex && python setup.py install --cuda_ext --cpp_ext


# >>BERT(ja)
RUN pip install transformers pyknp
USER root
ADD fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions && \
    chmod g+w /etc/passwd && \
    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc  && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER  && \
    fix-permissions /home/$NB_USER && \
    apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential cmake libboost-all-dev google-perftools libgoogle-perftools-dev wget unzip

RUN wget -P /home/jovyan -q http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/JapaneseBertPretrainedModel/Japanese_L-12_H-768_A-12_E-30_BPE_WWM_transformers.zip && \
    cd  /home/jovyan && unzip Japanese_L-12_H-768_A-12_E-30_BPE_WWM_transformers.zip

USER $NB_USER
RUN cd /home/$NB_USER && \
    wget http://lotus.kuee.kyoto-u.ac.jp/nl-resource/jumanpp/jumanpp-1.01.tar.xz && \
    tar xJvf jumanpp-1.01.tar.xz && \
    cd jumanpp-1.01 && \
    ./configure && \
    make

USER root
RUN cd /home/$NB_USER/jumanpp-1.01 && \
      make install
#     make install && \
#     pip install jupyter notebook && \
#     jupyter notebook --generate-config
# <<BERT(ja)


# >>mecab(neologd)
RUN apt-get update && apt-get install -y \
  mecab \
  libmecab-dev \
  mecab-ipadic-utf8 \
  sudo

WORKDIR /opt

RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git ; exit 0
RUN cd mecab-ipadic-neologd && \
  ./bin/install-mecab-ipadic-neologd -n -y && \
  echo "dicdir=/usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd">/etc/mecabrc

RUN pip install --upgrade pip && \
  pip install mecab-python3 \
  jaconv \
  unidic-lite
# ENV MECABRC /etc/mecabrc
# <<mecab(neologd)


# >>sudachi(full)
RUN pip install sudachipy \
    SudachiDict-full && \
    sudachipy link -t full    
# <<sudachi(full)

# >>fasttext
RUN wget https://github.com/facebookresearch/fastText/archive/v0.9.2.zip && \
  unzip v0.9.2.zip && \
  cd fastText-0.9.2 && \
  make && \
  pip install .
# <<fasttext


# >>python libraries
RUN pip install gensim \
    Janome
# <<python libraries


EXPOSE 8888

# RUN mkdir /etc/jupyter/ && fix-permissions /etc/jupyter/
# COPY jupyter_notebook_config.py /etc/jupyter/
# RUN chmod 777 -R /home/jovyan/.jupyter/

# >>node.js
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs
USER $NB_USER
# <<node.js


# >>jupyterlab extensions
ENV PATH /home/jovyan/.local/bin:$PATH
RUN pip install --upgrade jupyterlab \
    && pip install lckr-jupyterlab-variableinspector
#    && pip install jupyterlab_code_formatter \
#    && pip install lckr-jupyterlab-variableinspector \
#    && pip install jupyterlab-git==0.30.0b1 \
#    && pip install nbdime==3.0.0b1 
 
RUN jupyter lab build
#    jupyter serverextension enable --py jupyterlab-git && \
#    jupyter labextension enable jupyterlab-git toc jupyterlab_variableinspector nbdime \
# <<jupyterlab extensions


WORKDIR /home/jovyan
CMD /bin/bash
