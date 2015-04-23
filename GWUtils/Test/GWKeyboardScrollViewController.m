//
//  GWKeyboardScrollViewController.m
//  GWUtils
//
//  Created by huangqisheng on 15/4/22.
//  Copyright (c) 2015年 GW. All rights reserved.
//

#import "GWKeyboardScrollViewController.h"
#import "GWKeyboardScrollManager.h"

@interface GWKeyboardScrollViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField1;
@property (weak, nonatomic) IBOutlet UITextField *textField2;
@property (weak, nonatomic) IBOutlet UITextField *textField3;
@property (weak, nonatomic) IBOutlet UITextField *textField4;
@property (weak, nonatomic) IBOutlet UITextField *textField5;
@property (weak, nonatomic) IBOutlet UITextField *textField6;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) GWKeyboardScrollManager *scrollManager;

@end

@implementation GWKeyboardScrollViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _scrollManager = [[GWKeyboardScrollManager alloc] initWithScrollRootView:self.navigationController.view scrollingView:self.view];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [self.scrollManager keyboardWillShowWithFirstResponder:textField animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (self.textField6 == textField) {
        
        [self.textField6 resignFirstResponder];
    } else {
        
        [self.textField6 becomeFirstResponder];
    }
    return YES;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    [self.scrollManager keyboardWillShowWithFirstResponder:textView animated:YES];
}

@end
