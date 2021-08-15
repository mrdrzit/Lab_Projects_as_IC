print("\\Clear");
run("Close All");
//setOption("ExpandableArrays", true);
dir = getDirectory( "Onde est�o as fotos?" );
output = getDirectory( "Onde voc� quer guard�-las?" );

dir = replace(dir, "\\", "/"); // Conserta o nome do diret�rio para windows, colocando '/'
output = replace(output, "\\", "/");

//Crio uma janela para o usu�rio indicar quais valores ser�o usados no processamento
//TODO: Modular com base nos filtros poss�veis
Dialog.create("Valores para cortar s�rie Z e remover background");

Dialog.addMessage("Quais ser�o as fatias voc� quer remover do in�cio e fim da s�rie Z?");
Dialog.addNumber("In�cio:", 2);
Dialog.addNumber("Final:", 2);
Dialog.addMessage("Rolling window a ser usada:");
Dialog.addNumber("Valor para DAPI:", 100);
Dialog.addNumber("Valor para BDNF:", 100);

Dialog.show();

var n_inicial = Dialog.getNumber();
var n_final = Dialog.getNumber();
rolling_dapi = Dialog.getNumber();
rolling_bdnf = Dialog.getNumber();

//contents = getFileList( dir );
//list = split(contents, "\n");

var foto_atual = 1;
var list_file_names = getFileList(dir); //Me d� uma lista com o nome dos arquivos no diret�rio selecionado
	list_file_names = Array.sort(list_file_names); //Mas n�o discrimina entre 10x e 40x

debug_file_list = newArray //Array com o path apenas das fotos de 40x
z = 0;
for (i = 0; i < list_file_names.length; i++) { //Loop para selecionar apenas imagens .zvi
    if(File.isDirectory(dir + File.separator + list_file_names[i])){
		exit("Voc� precisa selecionar dentro da pasta onde est�o os arquivos");
    }
	if((endsWith(list_file_names[i], ".zvi")) && (indexOf(list_file_names[i], "40x") > 0)){
		debug_file_list[z] = dir + list_file_names[i];
        print(dir + list_file_names[i]);
    }else{
    continue;
        //exit("N�o � poss�vel processar arquivos que n�o s�o .zvi ou n�o s�o um Z_Stack\nComo por exemplo: " dir+list_file_names[i]);
    }
    z++;
}
Array.deleteValue(debug_file_list, "undefined") //Remove valores undefined
//Array.sort(list_file_names);
Array.sort(debug_file_list);
qtd = debug_file_list.length;

//Loop que faz o processamento das imagens
for ( i=0; i < qtd; i+=2) {
  showProgress(i, qtd);
  print("Estou processando a foto "+debug_file_list[i]);

  for (p=i; p<(i+2); p++){
    current_image = debug_file_list[p];
    open(current_image);
    tmp = getInfo("image.title");
    selectWindow(tmp);
    if(p == i){
        stack_size = nSlices;
        runtime_n_inicial = stack_size + 1 - (stack_size - n_inicial);
        runtime_n_final = stack_size - n_final;
        print("Vou come�ar na fatia "+runtime_n_inicial+"\ne terminar na fatia "+runtime_n_final+"\ne a foto tem "+stack_size +" fotos");
    }else if (stack_size == 1){
		exit("Atualmente o programa n�o consegue lidar\ncom fotos que n�o possuem uma s�rie Z\nComo a foto "+current_image); 
    }
  }
  
    
  run("Show All");
  list_open_filters = getList("image.titles"); //Faz um array com o nome das janelas abertas

  //Faz a compress�o da s�rie Z retirando as primeiras e �ltimas imagens pedidas pelo usu�rio
  for (j=0; j<list_open_filters.length; j++) {
    selectWindow(list_open_filters[j]);
    run("Z Project...",  "start=" + n_inicial + " stop="+n_final + " projection=[Max Intensity]");
    selectWindow(list_open_filters[j]);
    close();
    }

  run("Show All"); //Isso sempre vem antes pra ter certeza que todas as imagens que foram abertas podem ser selecionadas (a.k.a.: n�o est�o minimizadas)
  list_open_filters = getList("image.titles"); //Refaz o array porque a opera��o de comprimir a s�rie Z muda o nome da imagem

  //Retira o background
  //Aqui apenas o filtro do BRDU n�o � com um rolling window de 30px

  for (k=0; k<list_open_filters.length; k++) {
    if (indexOf(list_open_filters[k], "DCX") >= 0) {
      selectWindow(list_open_filters[k]);
      run("Subtract Background...", "rolling="+rolling_dcx);
      setOption("ScaleConversions", true);
      run("8-bit");
      }else if (indexOf(list_open_filters[k], "DAPI") >= 0) {
      selectWindow(list_open_filters[k]);
      run("Subtract Background...", "rolling="+rolling_dapi);
      setOption("ScaleConversions", true);
      run("8-bit");
      }else if (indexOf(list_open_filters[k], "BDNF") >= 0) {
      selectWindow(list_open_filters[k]);
      run("Subtract Background...", "rolling="+rolling_bdnf);
      setOption("ScaleConversions", true);
      run("8-bit");
    }
  }

  //Faz o composite com as tr�s imagens sem background
  Array.sort(list_open_filters);
  // Eplanation for the brackets: 
  // If your file names (i.e. the �values� of the parameters c1, c2, etc.) contain spaces, 
  // you have to enclose them in square brackets []
  run("Merge Channels...", "c2=["+ list_open_filters[0] + "] c3=[" + list_open_filters[1] + "] create keep");

  //Seleciona todas as imagaens e salva o composite como um .TIF para an�lise
  run("Show All");
  list_open_filters = getList("image.titles");

  nome_atual = File.nameWithoutExtension;

  selectImage("Composite");
  saveAs("PNG", output + nome_atual + "_composite" + ".png");
  foto_atual++;

  run("Show All");
  list = getList("image.titles");
  Array.sort(list);

  for (p=0; p<list.length; p++) {
    if (p==0){
      continue;
    }else{
      close(list[p]);
    }
  }
  run("Close All");
}

waitForUser("All images/filters processed");
