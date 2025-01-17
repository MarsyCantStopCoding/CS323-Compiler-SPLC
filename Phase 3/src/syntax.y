%{
    #include <string>
    #include <unordered_map>
    #include "lex.yy.c"
    #include "../include/syntaxTree.hpp"
    #include "../include/ir-util.hpp"

    using std::string;
    using std::unordered_map;
    #define YY_NO_UNPUT
    void yyerror(const char *s);
    bool type_A_error = 0;
    bool type_B_error = 0;
    void lineinfor(void);
    Node* root_node;
    unordered_map<string,Type*> symbolTable;
    vector<TAC *> ir_tac;
    unordered_map<string, int> id_int_mapper;
    unordered_map<int, string> int_reg_mapper;
    unordered_map<string, string> param_id_reg_mapper;
    bool has_loop = false;
    extern int isError;
    #define PARSER_error_OUTPUT stdout
%}

//%locations

%union{
    Node* node;
}

%token <node> INT FLOAT CHAR ID TYPE STRUCT IF ELSE WHILE FOR RETURN
%token <node> DOT SEMI COMMA ASSIGN LT LE GT GE NE EQ
%token <node> PLUS MINUS MUL DIV AND OR NOT LP RP LB RB LC RC UNKNOWN


%type <node> Program ExtDefList
%type <node> ExtDef ExtDecList Specifier StructSpecifier VarDec CompFunDec
%type <node> FunDec VarList ParamDec CompSt StmtList Stmt DefList
%type <node> Def DecList Dec Args Exp

%nonassoc UELSE
%nonassoc ELSE
%nonassoc UMINUS
%right ASSIGN 
%left OR AND 
%left LT LE GT GE NE EQ
%left PLUS MINUS
%left MUL DIV
%right NOT
%left LP RP LB RB DOT

%%
Program: ExtDefList{
    $$ = new Node(Node_Type::MEDIAN,"Program","",@$.first_line);
    $$->addChild({$1});
    root_node = $$;
}
;       
ExtDefList: /* to allow empty input */        {$$=new Node(Node_Type::NOTHING,"ExtDefList","",@$.first_line);}
    | ExtDef ExtDefList                       {$$=new Node(Node_Type::MEDIAN,"ExtDefList","",@$.first_line); $$->addChild({$1,$2});}
    ;         

ExtDef: error ExtDecList SEMI      {printf("Error type B at Line %d: Missing specifier\n",@$.first_line); type_B_error=1;}
    | Specifier ExtDecList SEMI    {$$=new Node(Node_Type::MEDIAN,"ExtDef","",@$.first_line); 
                                    $$->addChild({$1,$2,$3});
                                    ExtDefVisit_SES($$);
                                   }
    | Specifier SEMI               {$$=new Node(Node_Type::MEDIAN,"ExtDef","",@$.first_line); 
                                    $$->addChild({$1,$2}); 
                                    ExtDefVisit_SS($$);}
    | CompFunDec CompSt            {$$=new Node(Node_Type::MEDIAN,"ExtDef","",@$.first_line); 
                                    $$->addChild({$1->child[0], $1->child[1], $2});
                                    checkReturnType($$);
                                   }
    ;   

//实际结果是: ExtDef: Specifier FunDec 

CompFunDec: Specifier FunDec  { $$=new Node(Node_Type::MEDIAN,"CompFunDec","",@$.first_line);
                                $$->addChild({$1,$2});
                                ExtDefVisit_SFC($$);
                              }
ExtDecList: VarDec                            {$$=new Node(Node_Type::MEDIAN,"ExtDecList","",@$.first_line); $$->addChild({$1});}
    | VarDec COMMA ExtDecList                 {$$=new Node(Node_Type::MEDIAN,"ExtDecList","",@$.first_line); $$->addChild({$1,$2,$3});}
    ;         
/* specifier */       
    
Specifier: TYPE   {$$=new Node(Node_Type::MEDIAN,"Specifier","",@$.first_line); 
                   $$->addChild({$1});
                  }
    | StructSpecifier {$$=new Node(Node_Type::MEDIAN,"Specifier","",@$.first_line); 
                       $$->addChild({$1});
                       }
    ;         
StructSpecifier: STRUCT ID LC DefList RC      {$$=new Node(Node_Type::MEDIAN,"StructSpecifier","",@$.first_line); $$->addChild({$1,$2,$3,$4,$5});}
    | STRUCT ID                               {$$=new Node(Node_Type::MEDIAN,"StructSpecifier","",@$.first_line); $$->addChild({$1,$2});}
    ;         
/* declarator */          
    
VarDec: ID                                    {$$=new Node(Node_Type::MEDIAN,"VarDec","",@$.first_line); $$->addChild({$1});}
    | VarDec LB INT RB                        {$$=new Node(Node_Type::MEDIAN,"VarDec","",@$.first_line); $$->addChild({$1,$2,$3,$4});}
    ;         
FunDec: ID LP error                           {$$=new Node(Node_Type::MEDIAN,"FunDec","",@$.first_line); $$->addChild({$1,$2}); printf("Error type B at Line %d: Missing closing parenthesis ')'\n",@$.first_line); type_B_error=1;}
    | ID LP VarList RP                        {$$=new Node(Node_Type::MEDIAN,"FunDec","",@$.first_line); $$->addChild({$1,$2,$3,$4});FunDecVisit($$);}
    | ID LP RP                                {$$=new Node(Node_Type::MEDIAN,"FunDec","",@$.first_line); $$->addChild({$1,$2,$3});FunDecVisit($$);}
    ;         
VarList:ParamDec COMMA VarList                    {$$=new Node(Node_Type::MEDIAN,"VarList","",@$.first_line); $$->addChild({$1,$2,$3});}
    | ParamDec                                {$$=new Node(Node_Type::MEDIAN,"VarList","",@$.first_line); $$->addChild({$1});}
    ;         
ParamDec: Specifier VarDec                    {$$=new Node(Node_Type::MEDIAN,"ParamDec","",@$.first_line); $$->addChild({$1,$2});}
;         
/* statement */       
    
CompSt: LC DefList StmtList RC                {$$=new Node(Node_Type::MEDIAN,"CompSt","",@$.first_line); $$->addChild({$1,$2,$3,$4});}
;         
StmtList: /* to allow empty input */          {$$=new Node(Node_Type::NOTHING,"StmtList","",@$.first_line);}
    |Stmt StmtList                            {$$=new Node(Node_Type::MEDIAN,"StmtList","",@$.first_line); $$->addChild({$1,$2});}
    ;         
Stmt: Exp SEMI                                {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2});}
    | CompSt                                  {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1});}
    | RETURN Exp error                        {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2}); printf("Error type B at Line %d: Missing semicolon ';'\n",@$.first_line); type_B_error = 1;}
    | RETURN Exp SEMI                         {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2,$3});}
    | IF LP Exp RP Stmt  %prec UELSE          {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2,$3,$4,$5});}
    | IF LP Exp RP Stmt ELSE Stmt             {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2,$3,$4,$5,$6,$7});}
    | WHILE LP Exp RP Stmt                    {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2,$3,$4,$5});}
    | FOR LP Exp SEMI Exp SEMI Exp RP Stmt    {$$=new Node(Node_Type::MEDIAN,"Stmt","",@$.first_line); $$->addChild({$1,$2,$3,$4,$5,$6,$7,$8,$9});}

    ;         
/* local definition */        
DefList: /* to allow empty input */           {$$=new Node(Node_Type::NOTHING,"DefList","",@$.first_line);}
    | Def DefList                             {$$=new Node(Node_Type::MEDIAN,"DefList","",@$.first_line); $$->addChild({$1,$2});}
    ;         
Def: 
    Specifier DecList error                   {$$=new Node(Node_Type::MEDIAN,"Def","",@$.first_line); $$->addChild({$1,$2}); printf("Error type B at Line %d: Missing semicolon ';'\n",@$.first_line); type_B_error=1;}
    |Specifier DecList SEMI {$$=new Node(Node_Type::MEDIAN,"Def","",@$.first_line); 
                             $$->addChild({$1,$2,$3});
                             defVisit($$);
                            }
    ;         
DecList: Dec                                  {$$=new Node(Node_Type::MEDIAN,"DecList","",@$.first_line); $$->addChild({$1});}
    | Dec COMMA DecList                       {$$=new Node(Node_Type::MEDIAN,"DecList","",@$.first_line); $$->addChild({$1,$2,$3});}
    ;         
Dec: VarDec                                   {$$=new Node(Node_Type::MEDIAN,"Dec","",@$.first_line); $$->addChild({$1});}
    | VarDec ASSIGN Exp  {$$=new Node(Node_Type::MEDIAN,"Dec","",@$.first_line); 
                          $$->addChild({$1,$2,$3});
                         }
    ;         
/* Expression */          
Args: Exp COMMA Args {$$=new Node(Node_Type::MEDIAN,"Args","",@$.first_line); $$->addChild({$1,$2,$3});}
    | Exp            {$$=new Node(Node_Type::MEDIAN,"Args","",@$.first_line); $$->addChild({$1});}
    ;         
Exp: Exp ASSIGN Exp {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                      $$->addChild({$1,$2,$3});
                      checkRvalueInLeftSide($$);
                      checkAssignmentTypeMatching($$,$1,$3);
                    }
    | Exp AND Exp   {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line);
                     $$->addChild({$1,$2,$3});
                     setBoolOperatorType($$,$1,$3);
                    }
    | Exp OR Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setBoolOperatorType($$,$1,$3);
                    }
    | Exp LT Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp LE Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp GT Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp GE Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp NE Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp EQ Exp    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setCompareOperatorType($$,$1,$3);
                    }
    | Exp PLUS Exp  {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setAlrthOperatorType($$,$1,$3);
                    }
    | Exp MINUS Exp {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setAlrthOperatorType($$,$1,$3);
                    }
    | Exp MUL Exp   {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setAlrthOperatorType($$,$1,$3);
                    }
    | Exp DIV Exp   {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     setAlrthOperatorType($$,$1,$3);
                    }
    | LP Exp RP     {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3});
                     $$->type=$2->type;
                    }
    | MINUS Exp %prec UMINUS {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                              $$->addChild({$1,$2});
                              $$->var=$2->var; 
                              setAlrthOperatorType($$,$2);
                             }
    | NOT Exp                {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line);
                              $$->addChild({$1,$2});
                              $$->var=$2->var; 
                              setAlrthOperatorType($$,$2);
                             }
    | ID LP Args error {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); $$->addChild({$1,$2,$3}); 
                        printf("Error type B at Line %d: Missing closing parenthesis ')'\n",@$.first_line);
                        type_B_error = 1;
                       }
    | ID LP Args RP {checkExist_FUN($1);
                     checkParam_FUN($1,$3);
                     $$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                     $$->addChild({$1,$2,$3,$4});
                     getReturnTypeOfFunction($$,$1);
                    }
    | ID LP RP  {checkExist_FUN($1);
                 checkParam_FUN($1,nullptr);
                 $$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                 $$->addChild({$1,$2,$3});
                 getReturnTypeOfFunction($$,$1);
                 }
    | Exp LB Exp RB  {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line);
                      $$->addChild({$1,$2,$3,$4});
		              checkExists_Array($1);
                      getArrayType($$,$1,$3);
                     }
    | Exp DOT ID  {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
                   $$->addChild({$1,$2,$3});
                   checkTypeOfDot($$,$1,$3);
                  }
    | ID    {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
            $$->addChild({$1});
            checkExists_ID($1);
            idToExp($$,$1);
            }
    | INT   {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
             $$->addChild({$1});
             $$->var = Type::getPrimitiveINT();
            }
    | FLOAT {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
             $$->addChild({$1});
             $$->var = Type::getPrimitiveFLOAT();
            }
    | CHAR  {$$=new Node(Node_Type::MEDIAN,"Exp","",@$.first_line); 
            $$->addChild({$1}); 
            $$->var = Type::getPrimitiveCHAR();
            }
    | UNKNOWN  {type_A_error = 1;}
    ;       
%%
void yyerror(const char *s){
    // if (type_B_error){
        // printf("------------------------------\n");
        // printf("Error type B at Line %d: \n",yylineno);
        // printf("------------------------------\n");
    // }
	// printf("ERROR: %s at symbol '%s' on line %d\n", s, yytext, yylineno);
}
