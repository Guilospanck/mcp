# Naming conventions for odin

## Structs 

- names: `Ada_Case`
- fields: `snake_case`

Example:

```odin
My_Struct :: struct {
    one_field: string,
    another: string,
    yet_another_field: string
}
```

## Enums

- names: `Ada_Case`
- fields: `Ada_Case`

Example:

```odin
My_Enum :: enum {
    One_Field,
    Another,
    Yet_Another_Field,
}
```

## Procedures

- names: `Ada_Case`
- parameters: `snake_case`

Example:

```odin
My_Proc :: proc(first_parameter: string, another: string, yet_another: string) {
//
}
```

## Constants

- name `SCREAMING_SNAKE_CASE`

Example:

```odin
MY_CONSTANT :: "larry"
```

## Files/Folders

- name: `snake_case`

Examples: `my_file.odin`, `potato_master/tmp.odin`
