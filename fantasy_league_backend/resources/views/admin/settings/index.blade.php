@extends('layouts.app')

@section('content')
<div class="container">
    <h1>App Settings</h1>

    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <form method="POST" action="{{ route('admin.settings.update') }}">
        @csrf

        <table class="table">
            <thead>
                <tr>
                    <th>Key</th>
                    <th>Value</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @foreach($settings as $key => $value)
                <tr>
                    <td><code>{{ $key }}</code></td>
                    <td>
                        <input type="text" class="form-control" name="settings[{{ $key }}]" value="{{ old('settings.'.$key, $value ?? '') }}">
                    </td>
                    <td>
                        <form method="POST" action="{{ route('admin.settings.delete') }}" onsubmit="return confirm('Delete {{ $key }}?');">
                            @csrf
                            <input type="hidden" name="key" value="{{ $key }}">
                            <button type="submit" class="btn btn-danger btn-sm">Delete</button>
                        </form>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <div class="mb-3">
            <label class="form-label">Add new key</label>
            <div class="row">
                <div class="col-md-4">
                    <input type="text" class="form-control" name="new_key" placeholder="key_name (alphanumeric, underscores)">
                </div>
                <div class="col-md-6">
                    <input type="text" class="form-control" name="new_value" placeholder="value">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-secondary" type="submit">Add</button>
                </div>
            </div>
        </div>

        <button class="btn btn-primary" type="submit">Save changes</button>
    </form>
</div>
@endsection
