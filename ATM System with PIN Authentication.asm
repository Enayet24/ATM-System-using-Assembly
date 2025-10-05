.MODEL SMALL

print_string MACRO str
    MOV AH,9
    LEA DX,str
    INT 21H
ENDM

display_amount MACRO amount_var
    MOV AX, amount_var
    CALL display_number
ENDM

.STACK 100H
.DATA
             
; initial options variables             
pin_store dw 10000 dup(?)
balance_store dw 10000 dup(0) 
user_num dw 0 
current_user_num dw 0
current_user_balance dw ?

;Transaction history system
user_transaction_count dw 100 dup(0)  ; Track count per user (max 100 users)
transaction_history dw 500 dup(0)     ; 5 transactions
max_transactions dw 5

; Undo stack system
undo_stack dw 10 dup(?)
undo_stack_ptr dw 0
last_transaction_type dw ? ; 1=deposit, 2=withdrawal
last_transaction_amount dw ?

welcome_msg db "   *** Welcome to the ATM ***$"
home_msg db "== LOG IN or REGISTER ==$"
initial_opt1 db "1. Log into your account $"
initial_opt2 db "2. New user $"  
initial_opt3 db "3. Exit system $"
selected_opt db "Enter your selected option : $"

; new_pin_store variables
not_entry_txt db "Pin already taken. Try a new one $"
new_user_msg db "Enter a unique PIN ( 4 digit ) : $"
temp_pin dw ?
user_register db "Your PIN is registered SUCCESSFULLY! $"
             
; existing user pin              
existing_user_msg db "Enter your unique PIN ( 4 digit ) : $"
temp_pin2 dw ?
not_entry_txt2 db "PIN not matched! Please try again $"
no_user_txt db "No user found!! Please register first. $"

; main menu options 
login_msg db "Log in Successful !$"
logout_msg db "Logged out successfully! $" 
menu db "     === MAIN MENU ===$"
balance db "1. Balance Inquiry$"
withdrawal db "2. Cash Withdrawal$"
deposit db "3. Deposit Money$"
history db "4. Transaction History$"   
undo_option db "5. Undo Last Transaction$"
logout_option db "6. Log Out$"
exit db "7. Exit$"
line db "----------------------------$" 
options db "Please select any of the above options: $"

; Miscellaneous messages
b_msg1 db "))) BALANCE INQUIRY ((($"
b_msg2 db "Your Current Balance is: TK $"  

w_msg db "))) CASH WITHDRAWAL ((($"
oneK db "1. TK 1000$"
twoK db "2. TK 2000$"
fiveK db "3. TK 5000$"
tenK db "4. TK 10000$"
twentyK db "5. TK 20000$"
w_option db "Please select the amount you want to withdraw: $" 

d_msg1 db "))) MONEY DEPOSIT ((($"
d_msg2 db "Please enter the amount you want to deposit: $"

h_msg1 db "))) TRANSACTION HISTORY ((($"
h_msg2 db "Your Transaction History:$"
dp db " (Deposit)$"   
wd db " (Withdraw)$"

e_msg db "--- Thank You for using our System ---$"
invalid db "ERROR!! Invalid Option!$"
success db "Your Transaction is SUCCESSFULL!$"
insufficient_msg db "Insufficient Balance!$"
no_transaction_msg db "No transactions found!$"
undo_success_msg db "Last transaction undone successfully!$"
undo_fail_msg db "No transaction to undo!$"
deposit_prompt db "Enter amount (1-9999): $"

; Amount display variables
amount_temp dw ?
temp_remainder dw ?

.CODE
MAIN PROC
;initialize DS
MOV AX,@DATA
MOV DS,AX

; initial_options code  
print_string welcome_msg 
CALL next_line
CALL next_line

Initial_option_part:
    
    print_string home_msg
    CALL next_line
    CALL next_line
    print_string initial_opt1   
    CALL next_line
    print_string initial_opt2
    CALL next_line  
    print_string initial_opt3   
    CALL next_line
    print_string line
    CALL next_line
    print_string options
             
    MOV AH,1
    INT 21H
    SUB AL,48
    
    CMP AL,1
    JE CHECKER
    CMP AL,2
    JE ADDER
    CMP AL,3    
    JE END   
    
    CALL next_line 
    CALL next_line   
    print_string invalid    
    CALL next_line
    CALL next_line
    
    JMP Initial_option_part
     
CHECKER:
    CALL existing_user_pin_check
    JMP END
   
ADDER:  
    CALL next_line
    CALL proc_new_pin
    JMP END
    
MAIN_MENU: 
    
    CALL next_line
    CALL next_line
    print_string menu
    CALL next_line
    CALL next_line
    print_string balance
    CALL next_line                    
    print_string withdrawal
    CALL next_line
    print_string deposit
    CALL next_line
    print_string history
    CALL next_line
    print_string undo_option
    CALL next_line
    print_string logout_option
    CALL next_line
    print_string exit
    CALL next_line 
    print_string line
    CALL next_line
    print_string options
    
    MOV AH,1
    INT 21H
    SUB AL,30H
    
    CMP AL,1
    JE OPTION_1
    CMP AL,2
    JE OPTION_2
    CMP AL,3
    JE OPTION_3
    CMP AL,4
    JE OPTION_4
    CMP AL,5
    JE OPTION_5
    CMP AL,6
    JE OPTION_6
    CMP AL,7
    JE OPTION_7
    
    CALL next_line  
    print_string invalid
    CALL next_line
    CALL next_line
    JMP MAIN_MENU

OPTION_1: ; Balance 
    CALL next_line
    CALL next_line
    print_string b_msg1
    CALL next_line
    CALL next_line 
    print_string b_msg2
    

    CALL get_current_balance
    display_amount current_user_balance 
    CALL next_line
    CALL next_line
    JMP MAIN_MENU

OPTION_2: ; Cash Withdrawal  
    CALL next_line
    CALL next_line
    print_string w_msg
    CALL next_line
    CALL next_line 
    
    print_string oneK
    CALL next_line
    print_string twoK
    CALL next_line
    print_string fiveK
    CALL next_line
    print_string tenK
    CALL next_line
    print_string twentyK 
    CALL next_line
    print_string w_option
    
    MOV AH,1
    INT 21H
    SUB AL,30H
    
    CMP AL,1
    JE WITHDRAW_1K
    CMP AL,2
    JE WITHDRAW_2K
    CMP AL,3
    JE WITHDRAW_5K
    CMP AL,4
    JE WITHDRAW_10K
    CMP AL,5
    JE WITHDRAW_20K
    
    CALL next_line
    print_string invalid
    JMP MAIN_MENU
    
WITHDRAW_1K:
    MOV AX, 1000
    CALL process_withdrawal
    JMP MAIN_MENU
    
WITHDRAW_2K:
    MOV AX, 2000
    CALL process_withdrawal
    JMP MAIN_MENU
    
WITHDRAW_5K:
    MOV AX, 5000
    CALL process_withdrawal
    JMP MAIN_MENU
    
WITHDRAW_10K:
    MOV AX, 10000
    CALL process_withdrawal
    JMP MAIN_MENU
    
WITHDRAW_20K:
    MOV AX, 20000
    CALL process_withdrawal
    JMP MAIN_MENU

OPTION_3: ; Deposit Money
    
    CALL next_line
    CALL next_line
    print_string d_msg1
    CALL next_line
    CALL next_line
    print_string d_msg2
    CALL next_line
    print_string deposit_prompt
    
    CALL input_amount
    MOV AX, amount_temp
    CALL process_deposit
    
    CALL next_line
    CALL next_line
    JMP MAIN_MENU

OPTION_4: ; Trans History
    
    CALL next_line
    CALL next_line
    print_string h_msg1
    CALL next_line
    CALL next_line
    print_string h_msg2
    CALL next_line
    CALL next_line
    
    CALL show_transaction_history
    
    CALL get_current_balance
    print_string b_msg2
    display_amount current_user_balance
    
    CALL next_line
    CALL next_line
    JMP MAIN_MENU

OPTION_5: ; Undo
    CALL next_line
    CALL next_line
    CALL undo_last_transaction
    CALL next_line
    CALL next_line
    JMP MAIN_MENU

OPTION_6: ; Log Out
    CALL next_line
    CALL next_line
    print_string logout_msg
    

    MOV current_user_num, 0
    MOV current_user_balance, 0
    MOV last_transaction_type, 0
    MOV last_transaction_amount, 0
    
    CALL next_line
    CALL next_line
    print_string line
    CALL next_line
    CALL next_line
    
    JMP Initial_option_part

OPTION_7: ; Exit
    JMP END
    
END:
    CALL next_line
    CALL next_line
    print_string e_msg
    CALL next_line
    CALL next_line
    CALL next_line
    MOV AX,4C00H
    INT 21H
MAIN ENDP  


next_line PROC
    MOV AH,2
    MOV DL,10
    INT 21H
    MOV DL,13
    INT 21H
    RET
next_line ENDP

get_current_balance PROC
    PUSH SI
    PUSH AX
    
    MOV SI, current_user_num
    SHL SI, 1
    MOV AX, balance_store[SI]
    MOV current_user_balance, AX
    
    POP AX
    POP SI
    RET
get_current_balance ENDP

process_withdrawal PROC
    PUSH AX
    PUSH BX
    PUSH SI
    
    MOV BX, AX ; Store withdrawal amount
    CALL get_current_balance
    
    CMP current_user_balance, BX
    JB insufficient_balance
    
    SUB current_user_balance, BX
    
    MOV SI, current_user_num
    SHL SI, 1
    MOV AX, current_user_balance
    MOV balance_store[SI], AX
    
    MOV last_transaction_type, 2 
    MOV last_transaction_amount, BX
    
    MOV AX, BX
    NEG AX 
    CALL add_to_history
    
    CALL next_line
    CALL next_line
    print_string success
    CALL next_line
    JMP withdrawal_end
    
insufficient_balance:
    CALL next_line
    CALL next_line
    print_string insufficient_msg
    CALL next_line
    CMP current_user_balance, 0
    JNE OPTION_2
               
withdrawal_end:
    POP SI
    POP BX
    POP AX
    RET
process_withdrawal ENDP

process_deposit PROC
    PUSH AX
    PUSH SI
    
    MOV BX, AX 
    CALL get_current_balance

    ADD current_user_balance, BX
    
    ; Update balance in array
    MOV SI, current_user_num
    SHL SI, 1
    MOV AX, current_user_balance
    MOV balance_store[SI], AX
    
    MOV last_transaction_type, 1 ; Deposit
    MOV last_transaction_amount, BX
    
    MOV AX, BX 
    CALL add_to_history
    
    CALL next_line
    CALL next_line
    print_string success
    CALL next_line
    
    POP SI
    POP AX
    RET
process_deposit ENDP


input_amount PROC   ;4 digit input
    PUSH AX
    PUSH BX
    
    MOV amount_temp, 0
    
    ;first digit
    MOV AH, 1
    INT 21H
    SUB AL, 48
    MOV AH, 0
    MOV BX, 1000
    MUL BX
    MOV amount_temp, AX
    
    ;second digit
    MOV AH, 1
    INT 21H
    SUB AL, 48
    MOV AH, 0
    MOV BX, 100
    MUL BX
    ADD amount_temp, AX
    
    ;third digit
    MOV AH, 1
    INT 21H
    SUB AL, 48
    MOV AH, 0
    MOV BX, 10
    MUL BX
    ADD amount_temp, AX
    
    ;fourth digit
    MOV AH, 1
    INT 21H
    SUB AL, 48
    MOV AH, 0
    ADD amount_temp, AX
    
    POP BX
    POP AX
    RET
input_amount ENDP

display_number PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10
    MOV CX, 0
    
    divide_loop:
        MOV DX, 0
        DIV BX
        PUSH DX
        INC CX
        CMP AX, 0
        JNE divide_loop
    
    print_loop:
        POP DX
        ADD DL, 48
        MOV AH, 2
        INT 21H
        LOOP print_loop
        
    POP DX
    POP CX
    POP BX
    POP AX  
    
    RET
display_number ENDP


add_to_history PROC
    PUSH AX
    PUSH BX                         
    PUSH CX
    PUSH SI
    PUSH DI
    
    MOV DI, AX
    

    MOV SI, current_user_num
    SHL SI, 1 
    MOV CX, user_transaction_count[SI]  
    
    CMP CX, 5
    JL store_transaction
    
    MOV BX, current_user_num
    MOV AX, 5
    MUL BX
    SHL AX, 1
    MOV SI, AX 
    
    MOV CX, 4  
    
shift_loop:
    MOV AX, transaction_history[SI+2]
    MOV transaction_history[SI], AX
    ADD SI, 2
    LOOP shift_loop
    
    MOV transaction_history[SI], DI
    JMP history_done
    
store_transaction:

    MOV BX, current_user_num
    MOV AX, 5
    MUL BX
    ADD AX, CX  
    SHL AX, 1   
    MOV SI, AX
    
    MOV transaction_history[SI], DI
    
    MOV SI, current_user_num
    SHL SI, 1
    INC user_transaction_count[SI]
    
history_done:
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
add_to_history ENDP


show_transaction_history PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    
    MOV SI, current_user_num
    SHL SI, 1
    MOV CX, user_transaction_count[SI]
    
    CMP CX, 0
    JE no_transactions
    
    CMP CX, 5
    JLE show_all
    MOV CX, 5
    
show_all:

    MOV BX, current_user_num
    MOV AX, 5
    MUL BX
    SHL AX, 1
    MOV SI, AX
    

    MOV BX, CX 
    
show_loop:
    CMP BX, 0
    JE show_done
    
    MOV AX, transaction_history[SI]
    
    CMP AX, 0
    JGE positive_transaction
    
    NEG AX
    CALL display_number
    print_string wd

    CALL next_line
    JMP next_transaction
    
positive_transaction:

    CALL display_number
    print_string dp
    CALL next_line
    
next_transaction:
    ADD SI, 2
    DEC BX
    JMP show_loop
    
no_transactions:
    print_string no_transaction_msg
    CALL next_line
    
show_done:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
show_transaction_history ENDP


undo_last_transaction PROC
    PUSH AX
    PUSH BX
    PUSH SI
    
    CMP last_transaction_type, 0
    JE no_undo
    
    MOV BX, last_transaction_amount
    CALL get_current_balance
    
    CMP last_transaction_type, 1 ; Was deposit
    JE undo_deposit
    
    ADD current_user_balance, BX
    JMP update_balance
    
undo_deposit:

    SUB current_user_balance, BX
    
update_balance:

    MOV SI, current_user_num
    SHL SI, 1
    MOV AX, current_user_balance
    MOV balance_store[SI], AX

    MOV last_transaction_type, 0
    MOV last_transaction_amount, 0
    CALL remove_from_history
    
    print_string undo_success_msg
    JMP undo_end
    
no_undo:
    print_string undo_fail_msg
    
undo_end:
    POP SI
    POP BX
    POP AX
    RET
undo_last_transaction ENDP  


remove_from_history PROC
   
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    
    MOV SI, current_user_num
    SHL SI, 1
    MOV CX, user_transaction_count[SI]
    
    ; Check if user has any transactions
    CMP CX, 0
    JE no_transaction_to_remove
    
    DEC user_transaction_count[SI]
    
    ; Position = (current_user_num * 5 + (transaction_count - 1)) * 2  
    
    MOV BX, current_user_num
    MOV AX, 5
    MUL BX                    ; AX = current_user_num * 5
    ADD AX, CX             
    DEC AX                    ; Subtract 1 to get last transaction index
    SHL AX, 1               
    MOV SI, AX
    
    ; Clear the last transaction slot
    MOV transaction_history[SI], 0
    
no_transaction_to_remove:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
remove_from_history ENDP

; New user pin procedure
PROC proc_new_pin
    CALL next_line
    print_string new_user_msg
    
    ; 4th digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BX,1000
    MOV AH,0
    MUL BX
    MOV temp_pin,AX
   
    ; 3rd digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BL,100
    MOV AH,0
    MUL BL
    ADD temp_pin,AX
   
    ; 2nd digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BL,10
    MOV AH,0
    MUL BL
    ADD temp_pin,AX
   
    ; 1st digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV AH,0
    ADD temp_pin,AX
   
    ; Check if this already exists
    MOV SI,0
    MOV CX,user_num
    CMP CX,0
    JE add_array
    JMP check_pin
   
add_array:
    MOV AX, user_num
    MOV current_user_num, AX
    INC user_num
    MOV AX, temp_pin       
    MOV pin_store[SI], AX
   
    CALL next_line
    CALL next_line
    print_string user_register 
    CALL next_line
    CALL next_line
    JMP Initial_option_part
   
check_pin:
    MOV AX, pin_store[SI]
    CMP AX,temp_pin
    JE not_entry
    JMP increase
   
not_entry:
    CALL next_line  
    print_string not_entry_txt
    CALL proc_new_pin
   
increase:
    ADD SI,2 
    LOOP check_pin
    JMP add_array
   
    RET
ENDP proc_new_pin

; Existing user pin check
PROC existing_user_pin_check
    CALL next_line
    print_string existing_user_msg
    
    ; 4th digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BX,1000
    MOV AH,0
    MUL BX
    MOV temp_pin2,AX
   
    ; 3rd digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BL,100
    MOV AH,0
    MUL BL
    ADD temp_pin2,AX
   
    ; 2nd digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV BL,10
    MOV AH,0
    MUL BL
    ADD temp_pin2,AX
   
    ; 1st digit
    MOV AH,1
    INT 21H
    SUB AL,48
    MOV AH,0
    ADD temp_pin2,AX
   
    ; Check if this exists
    MOV CX,user_num
    MOV SI,0
    MOV BX,0 ; User index counter
    CMP CX,0
    JE no_user
    
check_pin2:
    MOV AX, pin_store[SI]
    CMP AX,temp_pin2
    JE found_user
    JMP increase2
    
found_user:
    MOV current_user_num, BX ; Set current user
    CALL next_line
    CALL next_line
    print_string login_msg
    CALL next_line
    CALL next_line
    print_string line
    CALL next_line
    CALL next_line
    JMP MAIN_MENU
    
increase2:    
    ADD SI,2
    INC BX
    LOOP check_pin2
    
not_entry2:
    CALL next_line  
    print_string not_entry_txt2
    CALL existing_user_pin_check
    
no_user:
    CALL next_line
    CALL next_line              
    print_string no_user_txt            
    CALL next_line
    print_string line
    CALL next_line
    CALL next_line          
    JMP Initial_option_part
    
    RET
ENDP existing_user_pin_check   

END MAIN
